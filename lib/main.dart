import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:printing/printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:zsdk/zsdk.dart';
// import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';

// void main() => runApp(MyApp());
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImpresionArchivosPdf(),
    );
  }
}

class ImpresionArchivosPdf extends StatefulWidget {

  @override
  _ImpresionArchivosPdfState createState() => _ImpresionArchivosPdfState();
}

class _ImpresionArchivosPdfState extends State<ImpresionArchivosPdf> {
  String filePath= '/storage/emulated/0/Android/data/com.example.impresion_zebra/files/downloads/factura_zebra_1.pdf';
  BluetoothDevice? zebraPrinter;
  // ----------------------------------------//
  void imprimirArchivo() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.bluetooth) || connectivityResult.contains(ConnectivityResult.wifi)) {
      File file = File(filePath);
      if (file.existsSync()) { //verificar existencia de archivo
        buscarImpresora();
      } else {
        _showDialog("Archivo No Encontrado", "No se encontró el archivo $filePath");
      }
    } else {
      _showDialog("Error", "No hay conexión disponible (Wi-Fi o Bluetooth requerido).");
    }
  }
  // Escanear impresoras Bluetooth
  void buscarImpresora() async {
    var status = await Permission.location.request();
    if (status.isGranted){
      debugPrint("-----iniciando-escaneo---------");
      FlutterBluePlus.startScan(timeout: Duration(seconds: 50));
      FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        // Imprimir todos los resultados de escaneo para depuración
        debugPrint("Resultados del escaneo: ${results.map((r) => r.device.platformName).toList()}");
        for (ScanResult r in results) {
          if (r.device.platformName.contains("ZQ-ELSA")){
            zebraPrinter = r.device;
            break;
          }
        }
      });
      if (zebraPrinter!=null){
        await zebraPrinter!.connect();
        _showDialog("Conectado", "Conectado a la impresora ${zebraPrinter!.platformName}");
        enviarAImpresora();
      }else{
         _showDialog("No se encontraron impresoras", "No se encontraron impresoras Zebra.");
      }
    } else {
    _showDialog("Permiso Denegado", "Se necesitan permisos de ubicación para escanear dispositivos Bluetooth.");
    }
  }
   // Enviar archivo PDF a la impresora
  void enviarAImpresora() async {
    File file = File(filePath);
    List<int> pdfBytes  = await file.readAsBytes(); // Leer PDF como bytes
    
    Uint8List uint8ListBytes = Uint8List.fromList(pdfBytes); // Convertir a Uint8List
    await Printing.layoutPdf(
      onLayout: (format) async =>uint8ListBytes, // Convertido correctamente
    );
    //Printer? impresora = await Printing.pickPrinter(context: context);
    // debugPrint("Resultados del escaneo PRUEBA1: ${zebraPrinter}");
    // await Printing.directPrintPdf(
    //   printer: Printer(url: zebraPrinter!.remoteId.str),
    //   onLayout: (format) => uint8ListBytes,
    // );
    // List<Printer> printers = await Printing.listPrinters();
    // debugPrint("Resultados del escaneo PRUEBA1: ${printers}");
    // debugPrint("Resultados del escaneo PRUEBA: ${printers.map((r) => r.name).toList()}");
    // if (printers.isNotEmpty) {
    //   Printer selectedPrinter = printers[0];
    //     await Printing.directPrintPdf(
    //       printer: selectedPrinter,
    //       onLayout: (format) => uint8ListBytes,
    //     );
    // } else {
    //   debugPrint('No se encontraron impresoras locales.');
    // }
 
    // Printing.directPrintPdf(printer: printer,onLayout: (format) => uint8ListBytes);
   
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
          onPressed: imprimirArchivo,//findFile,
          child: Text("Imprimir en Zebra"),
        ),
      ),
    );
  }
}
