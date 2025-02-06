import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


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
    } else {
      _showDialog("Archivo No Encontrado", "No se encontró el archivo factura_zebra_1.pdf");
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
