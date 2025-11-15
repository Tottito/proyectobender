import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../modelos/propiedad.dart';

class PropiedadesViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Propiedad> _lista = [];
  List<Propiedad> get propiedades => _lista;

  bool cargando = true;
  String? error;

  StreamSubscription<QuerySnapshot>? _subscription;

  PropiedadesViewModel() {
    escucharPropiedades();
  }

  /// Escucha cambios en tiempo real de Firebase
  void escucharPropiedades() {
    try {
      cargando = true;
      error = null;
      notifyListeners();

      // ⚠️ SIN orderBy para evitar problemas con índices
      _subscription = _db
          .collection('propiedades')
          .snapshots()
          .listen(
            (snapshot) {
          debugPrint('📦 Documentos recibidos: ${snapshot.docs.length}');

          _lista = snapshot.docs.map((doc) {
            debugPrint('📄 Procesando doc ID: ${doc.id}');
            return Propiedad.fromMap(doc.id, doc.data());
          }).toList();

          // Ordenar localmente por fecha (si existe)
          _lista.sort((a, b) {
            // Ordenar alfabéticamente por título si no hay createdAt
            return b.titulo.compareTo(a.titulo);
          });

          cargando = false;
          debugPrint('✅ Total propiedades cargadas: ${_lista.length}');
          notifyListeners();
        },
        onError: (e) {
          error = "Error al cargar propiedades: $e";
          cargando = false;
          notifyListeners();
          debugPrint('❌ Error en stream de propiedades: $e');
        },
      );
    } catch (e) {
      error = "Error de conexión: $e";
      cargando = false;
      notifyListeners();
      debugPrint('❌ Error iniciando stream: $e');
    }
  }

  /// AGREGAR una nueva propiedad
  Future<void> agregar(Propiedad p) async {
    try {
      final data = p.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();

      await _db.collection('propiedades').add(data);
      debugPrint('✅ Propiedad agregada: ${p.titulo}');
    } catch (e) {
      error = "Error al agregar propiedad: $e";
      notifyListeners();
      debugPrint('❌ Error agregando propiedad: $e');
      rethrow;
    }
  }

  /// ACTUALIZAR una propiedad existente
  Future<void> actualizar(String id, Propiedad p) async {
    try {
      if (id.isEmpty) {
        throw Exception('ID de propiedad vacío');
      }

      await _db.collection('propiedades').doc(id).update(p.toMap());
      debugPrint('✅ Propiedad actualizada: ${p.titulo} (ID: $id)');
    } catch (e) {
      error = "Error al actualizar propiedad: $e";
      notifyListeners();
      debugPrint('❌ Error actualizando propiedad: $e');
      rethrow;
    }
  }

  /// ELIMINAR una propiedad
  Future<void> eliminar(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('ID de propiedad vacío');
      }

      await _db.collection('propiedades').doc(id).delete();
      debugPrint('✅ Propiedad eliminada (ID: $id)');
    } catch (e) {
      error = "Error al eliminar propiedad: $e";
      notifyListeners();
      debugPrint('❌ Error eliminando propiedad: $e');
      rethrow;
    }
  }

  /// Limpiar error manualmente
  void limpiarError() {
    error = null;
    notifyListeners();
  }

  /// 🔧 Función de utilidad: Agregar createdAt a propiedades que no lo tengan
  Future<void> repararPropiedadesSinFecha() async {
    try {
      final snapshot = await _db.collection('propiedades').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Si no tiene createdAt, agregarlo
        if (data['createdAt'] == null) {
          await doc.reference.update({
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('🔧 Reparado documento: ${doc.id}');
        }
      }

      debugPrint('✅ Reparación completada');
    } catch (e) {
      debugPrint('❌ Error reparando propiedades: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    debugPrint('🔌 PropiedadesViewModel disposed');
    super.dispose();
  }
}