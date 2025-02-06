import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:printing/printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// void main() => runApp(MyApp());
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FileFinderScreen(),
    );
  }
}

class FileFinderScreen extends StatefulWidget {
  @override
  _FileFinderScreenState createState() => _FileFinderScreenState();
}

class _FileFinderScreenState extends State<FileFinderScreen> {
  BluetoothDevice? zebraPrinter;
  // ----------------------------------------
  void verificarConexionBuscarArchivo() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.bluetooth) || connectivityResult.contains(ConnectivityResult.wifi)) {
      debugPrint("Conectividad disponible (Wi-Fi o Bluetooth):${connectivityResult}");
      findFile();
    } else {
      _showDialog("Error", "No hay conexión disponible (Wi-Fi o Bluetooth requerido).");
    }
  }
  Future<void> findFile() async{
    Directory? directorioBase =await getDownloadsDirectory();
    directorioBase ??= await getApplicationDocumentsDirectory();
    if (!await directorioBase.exists()){
        await directorioBase.create(recursive: true);
    }
    String directoryPath = p.join(directorioBase.path,'factura_zebra_1.pdf',);
    File file = File(directoryPath);
    if (file.existsSync()) {
      //_showDialog("Archivo Encontrado", "El archivo factura_zebra_1.pdf fue encontrado en Descargas.");
       buscarImpresora();
    } else {
      _showDialog("Archivo No Encontrado", "No se encontró el archivo factura_zebra_1.pdf");
    }
  }
   // Escanear impresoras Bluetooth
  void buscarImpresora() async {
   // _showDialog("Buscando Impresoras", "Escaneando dispositivos Bluetooth...");
     var status = await Permission.location.request();
    if (status.isGranted){
      debugPrint("-----iniciando-escaneo---------");
      FlutterBluePlus.startScan(timeout: Duration(seconds: 50));
      FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        debugPrint("------ Escaneo completado ------");
        // Imprimir todos los resultados de escaneo para depuración
        debugPrint("Resultados del escaneo: ${results.map((r) => r.device.name).toList()}");
        for (ScanResult r in results) {
          if (r.device.name.contains("ZQ-ELSA")){
            zebraPrinter = r.device;
            _showDialog("Impresora Encontrada", "Impresora ${r.device.name} encontrada. Conectando...");
            conectarseAImpresora();
            break;
          }
        }
      });
       // Si no se encuentran resultados después de 30 segundos, muestra un mensaje
      Future.delayed(Duration(seconds: 30), () {
        if (zebraPrinter == null) {
          _showDialog("No se encontraron impresoras", "No se encontraron impresoras Zebra.");
        }
      });
    } else {
    _showDialog("Permiso Denegado", "Se necesitan permisos de ubicación para escanear dispositivos Bluetooth.");
    }
  }
   // Conectarse a la impresora
  void conectarseAImpresora() async {
    if (zebraPrinter != null) {
      await zebraPrinter!.connect();
      _showDialog("Conectado", "Conectado a la impresora Zebra ZQ320.");
      enviarAImpresora();
    } else {
      _showDialog("Error", "No se encontró la impresora.");
    }
  }

   // Enviar archivo PDF a la impresora
  void enviarAImpresora() async {
    Directory? directorioBase =await getDownloadsDirectory();
    directorioBase ??= await getApplicationDocumentsDirectory();
    String filePath = p.join(directorioBase.path,'factura_zebra_1.pdf',);
    //String filePath = "/storage/emulated/0/Download/factura_zebra_1.pdf";
    File file = File(filePath);

    if (!file.existsSync()) {
      _showDialog("Error", "No se encontró el archivo para imprimir.");
      return;
    }

    List<int> bytes = await file.readAsBytes(); // Leer PDF como bytes
    Uint8List uint8ListBytes = Uint8List.fromList(bytes); // Convertir a Uint8List
    await Printing.layoutPdf(
      onLayout: (format) async =>uint8ListBytes, // Convertido correctamente
    );
    _showDialog("Impresión Enviada", "El archivo ha sido enviado a la impresora.");
  }

  // mensaje de informacion
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Buscar Archivo en con conectividad")),
      body: Center(
        child: ElevatedButton(
          onPressed: verificarConexionBuscarArchivo,//findFile,
          child: Text("Buscar Archivo"),
        ),
      ),
    );
  }
}
