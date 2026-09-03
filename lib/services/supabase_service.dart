import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/equipo_model.dart';
import '../models/salon_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? get client {
    if (SupabaseConfig.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (e) {
        debugPrint('Supabase client no inicializado: $e');
        return null;
      }
    }
    return null;
  }

  bool get isConnected => client != null;

  // StreamController para alimentar la UI de forma resiliente
  final StreamController<List<Equipo>> _equiposBroadcastController =
      StreamController<List<Equipo>>.broadcast();
  Timer? _pollingTimer;
  StreamSubscription? _realtimeSubscription;
  bool _isRealtimeActive = false;

  bool get isRealtimeActive => _isRealtimeActive;

  List<Equipo> _cachedEquipos = [];

  List<Equipo> _generateDefault30Pcs({String salonId = 'salon-317'}) {
    return List.generate(30, (index) {
      final num = (index + 1).toString().padLeft(2, '0');
      final hasError = [2, 7, 14, 23].contains(index + 1);
      return Equipo(
        id: 'pc-$num',
        codigo: 'PC-317-$num',
        estado: !hasError,
        observacion: hasError
            ? (index + 1 == 2
                ? 'Sin señal de video'
                : (index + 1 == 7
                    ? 'Teclado: tecla espacio rota'
                    : 'No enciende'))
            : 'Core i7 · 16GB · OK',
        salonId: salonId,
      );
    });
  }

  // ==========================
  // AUTENTICACIÓN
  // ==========================

  User? get currentUser => client?.auth.currentUser;

  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!isConnected) {
      await Future.delayed(const Duration(milliseconds: 600));
      return null;
    }
    return await client!.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String nombre,
    String rol = 'aprendiz',
  }) async {
    if (!isConnected) {
      await Future.delayed(const Duration(milliseconds: 600));
      return null;
    }
    return await client!.auth.signUp(
      email: email,
      password: password,
      data: {
        'nombre': nombre,
        'rol': rol,
      },
    );
  }

  Future<void> signOut() async {
    if (isConnected) {
      await client!.auth.signOut();
    }
  }

  // ==========================
  // STREAM DE EQUIPOS (HÍBRIDO REALTIME + HTTP POLLING RESILIENTE)
  // Cumple con la Actividad 3 y 3.2 de la Guía SENA (CDC vs Polling)
  // ==========================
  Stream<List<Equipo>> getEquiposStream({String? salonId}) {
    // Si no está conectado, emitir datos de demostración
    if (!isConnected) {
      _cachedEquipos = _generateDefault30Pcs();
      Timer.run(() => _equiposBroadcastController.add(_cachedEquipos));
      return _equiposBroadcastController.stream;
    }

    // Iniciar carga inmediata por REST
    _fetchEquiposRest(salonId);

    // Intentar suscripción Realtime nativa de Supabase
    _setupRealtimeStream(salonId);

    return _equiposBroadcastController.stream;
  }

  Future<void> _fetchEquiposRest(String? salonId) async {
    if (!isConnected) return;
    try {
      final query = client!.from('equipos').select().order('codigo');
      final response = await query;
      final list = (response as List)
          .map((item) => Equipo.fromJson(item))
          .where((eq) {
        if (salonId == null || salonId.isEmpty) return true;
        return eq.salonId == salonId;
      }).toList();

      if (list.isNotEmpty) {
        _cachedEquipos = list;
        _equiposBroadcastController.add(_cachedEquipos);
      } else {
        // La tabla está vacía en Supabase: auto-sembrar los 30 puestos
        debugPrint('Tabla equipos vacía en Supabase. Sembrando 30 PCs...');
        await seed30EquiposIfEmpty();
        final reload = await client!.from('equipos').select().order('codigo');
        final reloadedList = (reload as List).map((i) => Equipo.fromJson(i)).toList();
        _cachedEquipos = reloadedList.isNotEmpty ? reloadedList : _generateDefault30Pcs();
        _equiposBroadcastController.add(_cachedEquipos);
      }
    } catch (e) {
      debugPrint('Error en REST fetch equipos: $e');
      if (_cachedEquipos.isEmpty) {
        _cachedEquipos = _generateDefault30Pcs();
        _equiposBroadcastController.add(_cachedEquipos);
      }
    }
  }

  void _setupRealtimeStream(String? salonId) {
    _realtimeSubscription?.cancel();

    try {
      final stream = client!
          .from('equipos')
          .stream(primaryKey: ['id'])
          .order('codigo', ascending: true);

      _realtimeSubscription = stream.listen(
        (dataList) {
          _isRealtimeActive = true;
          final updated = dataList.map((item) => Equipo.fromJson(item)).where((eq) {
            if (salonId == null || salonId.isEmpty) return true;
            return eq.salonId == salonId;
          }).toList();

          if (updated.isNotEmpty) {
            _cachedEquipos = updated;
            _equiposBroadcastController.add(_cachedEquipos);
          }
        },
        onError: (error) {
          debugPrint('⚠️ Realtime CDC channel error: $error. Activando polling HTTP...');
          _isRealtimeActive = false;
          _startHttpPolling(salonId);
        },
      );
    } catch (e) {
      debugPrint('Error iniciando stream realtime: $e. Activando polling HTTP...');
      _isRealtimeActive = false;
      _startHttpPolling(salonId);
    }
  }

  void _startHttpPolling(String? salonId) {
    _pollingTimer?.cancel();
    // Sondeo periódico cada 2.5 segundos (Polling HTTP) como contingencia
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _fetchEquiposRest(salonId);
    });
  }

  // ==========================
  // OPERACIONES CRUD
  // ==========================

  Future<void> updateEquipoEstado({
    required String id,
    required bool nuevoEstado,
    String? observacion,
  }) async {
    // 1. Actualización optimista inmediata en la UI
    final index = _cachedEquipos.indexWhere((e) => e.id == id);
    if (index != -1) {
      _cachedEquipos[index] = _cachedEquipos[index].copyWith(
        estado: nuevoEstado,
        observacion: observacion ?? _cachedEquipos[index].observacion,
      );
      _equiposBroadcastController.add(List.from(_cachedEquipos));
    }

    // 2. Persistencia en Supabase
    if (isConnected) {
      try {
        final updateData = <String, dynamic>{'estado': nuevoEstado};
        if (observacion != null) {
          updateData['observacion'] = observacion;
        }
        await client!.from('equipos').update(updateData).eq('id', id);
      } catch (e) {
        debugPrint('Error actualizando equipo en Supabase: $e');
        rethrow;
      }
    }
  }

  Future<void> createEquipo({
    required String codigo,
    required bool estado,
    required String observacion,
    String? salonId,
  }) async {
    if (isConnected) {
      String? targetSalonId = salonId;
      if (targetSalonId == null || targetSalonId.isEmpty) {
        try {
          final salonRes = await client!
              .from('salones')
              .select('id')
              .eq('nombre', 'Salón 317')
              .maybeSingle();
          if (salonRes != null) {
            targetSalonId = salonRes['id']?.toString();
          }
        } catch (_) {}
      }

      final data = <String, dynamic>{
        'codigo': codigo,
        'estado': estado,
        'observacion': observacion,
      };
      if (targetSalonId != null) {
        data['salon_id'] = targetSalonId;
      }

      await client!.from('equipos').insert(data);
      await _fetchEquiposRest(targetSalonId);
    } else {
      final nuevo = Equipo(
        id: 'demo-pc-${DateTime.now().millisecondsSinceEpoch}',
        codigo: codigo,
        estado: estado,
        observacion: observacion,
        salonId: salonId ?? 'salon-317',
      );
      _cachedEquipos.add(nuevo);
      _equiposBroadcastController.add(List.from(_cachedEquipos));
    }
  }

  // ==========================
  // SALONES
  // ==========================

  Future<List<Salon>> getSalones() async {
    if (isConnected) {
      try {
        final response = await client!.from('salones').select().order('nombre');
        final list =
            (response as List).map((item) => Salon.fromJson(item)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint('Error al consultar salones: $e');
      }
    }
    return [
      Salon(id: 'salon-317', nombre: 'Salón 317'),
      Salon(id: 'salon-318', nombre: 'Salón 318'),
      Salon(id: 'lab-redes', nombre: 'Laboratorio de Redes'),
    ];
  }

  // ==========================
  // INICIALIZADOR DE 30 PCs EN SUPABASE
  // ==========================
  Future<void> seed30EquiposIfEmpty() async {
    if (!isConnected) return;

    try {
      // 1. Buscar o crear Salón 317
      String salonId;
      final salonesRes = await client!
          .from('salones')
          .select('id')
          .eq('nombre', 'Salón 317')
          .maybeSingle();

      if (salonesRes != null && salonesRes['id'] != null) {
        salonId = salonesRes['id'];
      } else {
        final inserted = await client!
            .from('salones')
            .insert({'nombre': 'Salón 317'})
            .select('id')
            .single();
        salonId = inserted['id'];
      }

      // 2. Insertar 30 PCs
      final List<Map<String, dynamic>> batch = [];
      for (int i = 1; i <= 30; i++) {
        final num = i.toString().padLeft(2, '0');
        final isFault = [2, 7, 14, 23].contains(i);
        batch.add({
          'codigo': 'PC-317-$num',
          'estado': !isFault,
          'observacion': isFault
              ? (i == 2 ? 'Sin señal de video' : 'Falla de teclado / hardware')
              : 'Core i7 · 16GB · OK',
          'salon_id': salonId,
        });
      }
      await client!.from('equipos').upsert(batch, onConflict: 'codigo');
      await _fetchEquiposRest(salonId);
    } catch (e) {
      debugPrint('Error al sembrar datos: $e');
    }
  }
}
