import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mixin que contiene la lógica de negocio para la configuración de impresoras Bluetooth
///
/// Requiere que la clase que lo use implemente:
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
/// - Método: setState (de State)
mixin PrinterLogicMixin<T extends StatefulWidget> on State<T> {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  
  /// Lista de dispositivos Bluetooth encontrados
  List<BluetoothDevice> devices = [];
  
  /// Dispositivo actualmente seleccionado
  BluetoothDevice? selectedDevice;
  
  /// Estado de conexión actual
  bool connected = false;
  
  /// Estado de escaneo de dispositivos
  bool scanning = false;
  
  /// Variable de estado para controlar el loading general
  bool isLoading = false;

  /// Setter para actualizar el estado de loading
  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        isLoading = value;
      });
    }
  }

  /// Inicializa la impresora: solicita permisos y escanea dispositivos
  Future<void> initPrinter() async {
    setLoading(true);
    try {
      // 1. Pedir permisos (Android 12+ requiere permisos extra de Bluetooth)
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Necesario en versiones viejas de Android
      ].request();

      // 2. Verificar estado actual
      bool? isConnected = await _bluetooth.isConnected;
      if (isConnected == true && mounted) {
        setState(() => connected = true);
      }

      // 3. Cargar lista inicial
      await scanDevices();
    } catch (e) {
      debugPrint("Error inicializando impresora: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Escanea dispositivos Bluetooth emparejados
  Future<void> scanDevices() async {
    if (!mounted) return;

    setState(() => scanning = true);
    try {
      List<BluetoothDevice> foundDevices = await _bluetooth.getBondedDevices();
      if (mounted) {
        setState(() => devices = foundDevices);
      }
    } catch (e) {
      debugPrint("Error escaneando dispositivos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error escaneando: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => scanning = false);
      }
    }
  }

  /// Conecta a un dispositivo Bluetooth
  ///
  /// [device]: El dispositivo al que se desea conectar
  Future<void> connect(BluetoothDevice device) async {
    if (!mounted) return;

    setState(() => selectedDevice = device);
    setLoading(true);

    try {
      // Desconectar si ya hay una conexión activa
      if (connected) {
        await _bluetooth.disconnect();
      }

      await _bluetooth.connect(device);

      if (mounted) {
        setState(() => connected = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Conectado a ${device.name ?? 'Dispositivo'}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error conectando dispositivo: $e");
      if (mounted) {
        setState(() => connected = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al conectar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Desconecta el dispositivo actual
  Future<void> disconnect() async {
    if (!mounted) return;

    setLoading(true);
    try {
      await _bluetooth.disconnect();
      if (mounted) {
        setState(() {
          connected = false;
          selectedDevice = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Desconectado"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error desconectando: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al desconectar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Imprime un test para verificar que la conexión funciona
  Future<void> testPrint() async {
    if (!mounted) return;

    final isConnected = await _bluetooth.isConnected;
    if (isConnected != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No hay impresora conectada"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setLoading(true);
    try {
      _bluetooth.printNewLine();
      _bluetooth.printCustom("TEST EXITOSO", 2, 1);
      _bluetooth.printCustom("Tu sistema esta listo.", 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Test enviado a la impresora"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error imprimiendo test: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al imprimir: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }
}
