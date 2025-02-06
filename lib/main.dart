import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:zebrautility/ZebraPrinter.dart';
import 'package:zebrautility/zebrautility.dart';

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
  // conectar impresora
  ZebraPrinter? zebraPrinter;
  bool searchingWifi = false;
  bool searchingBluetooth = false;
  List<AvailablePrinter> availablePrinters = <AvailablePrinter>[];
  AvailablePrinter? printer;

  @override
  void initState() {
    super.initState();
    initializePrinter();
  }
  // ----------------------------------------
  void verificarConexionBuscarArchivo() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.bluetooth) || connectivityResult.contains(ConnectivityResult.wifi)) {
      debugPrint("Conectividad disponible (Wi-Fi o Bluetooth):$connectivityResult");
      findFile();
    } else {
      _showDialog("Error", "No hay conexión disponible (Wi-Fi o Bluetooth requerido).");
    }
  }
  void findFile() {
    // Ruta típica de Descargas en Android
    String downloadsPath = "/storage/emulated/0/Download/factura_zebra_1.pdf";

    File file = File(downloadsPath);
    if (file.existsSync()) {
      _showDialog("Archivo Encontrado", "El archivo factura_zebra_1.pdf fue encontrado en Descargas.");
       imprimirPdf(file); // Llamar a la función para imprimir el PDF
    } else {
      _showDialog("Archivo No Encontrado", "No se encontró el archivo factura_zebra_1.pdf");
    }
  }
  // Funcion para enviar el PDF a la impresora
  void imprimirPdf(File pdfFile) async {
    if (zebraPrinter != null) {
      // Aquí se manda el archivo PDF a la impresora
      String pdfFilePath = pdfFile.path;

      // Ejemplo de comando ZPL para impresión de archivo PDF
      //zebraPrinter?.print("! U1 setvar \"pdf.printfile\" \"$pdfFilePath\"");
      debugPrint("Enviando archivo a la impresora: $pdfFilePath");
      _showDialog("Impresión", "El archivo PDF ha sido enviado a la impresora.");
    } else {
      _showDialog("Error de Impresora", "No hay impresora conectada.");
    }
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
  // Inicializar la impresora Zebra
  void initializePrinter() async {
    zebraPrinter ??= await Zebrautility.getPrinterInstance(
      onPrinterFound: (name, ipAddress, isWifi) {
        debugPrint("Impresora encontrada: $name $ipAddress $isWifi");
        availablePrinters.add(AvailablePrinter(name: name, ipAddress: ipAddress, isWifi: isWifi));
      },
      onPrinterDiscoveryDone: () {
        debugPrint("Descubrimiento de impresoras finalizado.");
      },
      onDiscoveryError: (int errorCode, String error) {
        debugPrint("Error en el descubrimiento: $error");
      },
      onChangePrinterStatus: (status, color) {
        if (status == "Done") {
          debugPrint("Conexión exitosa con la impresora.");
        }
      },
      onPermissionDenied: () {
        debugPrint("Permiso denegado.");
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

// Clase para representar las impresoras disponibles
class AvailablePrinter {
  String name;
  String ipAddress;
  bool isWifi;

  AvailablePrinter({required this.name, required this.ipAddress, this.isWifi = false});
}