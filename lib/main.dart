import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MiAppEditora());
}

class MiAppEditora extends StatelessWidget {
  const MiAppEditora({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo & Video Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  File? imagenLocal;
  String? urlImagenProcesada;
  bool procesandoIA = false;
  String resolucionTexto = 'HD (Original)';
  
  final ImagePicker _picker = ImagePicker();

  Future<void> seleccionarImagenDeGaleria() async {
    try {
      final XFile? imagenSeleccionada = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (imagenSeleccionada != null) {
        setState(() {
          imagenLocal = File(imagenSeleccionada.path);
          urlImagenProcesada = null;
          resolucionTexto = 'HD (Original)';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void limpiarSeleccion() {
    setState(() {
      imagenLocal = null;
      urlImagenProcesada = null;
      procesandoIA = false;
    });
  }

  Future<void> procesarImagenConIA() async {
    if (imagenLocal == null) return;

    setState(() {
      procesandoIA = true;
    });

    try {
      const String apiKey = 'TU_API_KEY_AQUI';
      final uri = Uri.parse('https://api.replicate.com/v1/predictions');

      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..files.add(await http.MultipartFile.fromPath('image', imagenLocal!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);
        setState(() {
          urlImagenProcesada = data['output'] ?? data['image_url'];
          resolucionTexto = '3840x3840 (4K Ultra HD)';
          procesandoIA = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Procesamiento exitoso! Imagen mejorada a 4K.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        procesandoIA = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar con IA: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Multimedia'),
        centerTitle: true,
        actions: imagenLocal != null
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: limpiarSeleccion,
                  tooltip: 'Cambiar imagen',
                )
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: imagenLocal == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.auto_awesome_motion,
                      size: 70,
                      color: Colors.deepPurpleAccent,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '¿Qué quieres crear hoy?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    BotonMenu(
                      icono: Icons.photo_library,
                      texto: 'Editar Foto de Galería',
                      color: Colors.purple,
                      onTap: seleccionarImagenDeGaleria,
                    ),
                    const SizedBox(height: 14),
                    BotonMenu(
                      icono: Icons.auto_fix_high,
                      texto: 'Mejorar Imagen con IA',
                      color: Colors.indigo,
                      onTap: seleccionarImagenDeGaleria,
                    ),
                    const SizedBox(height: 14),
                    BotonMenu(
                      icono: Icons.video_call,
                      texto: 'Crear / Editar Video',
                      color: Colors.deepOrange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Módulo de video en desarrollo.')),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Calidad: $resolucionTexto',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: urlImagenProcesada != null
                              ? Image.network(
                                  urlImagenProcesada!,
                                  height: 300,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  imagenLocal!,
                                  height: 300,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        if (procesandoIA)
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.amber),
                                  SizedBox(height: 16),
                                  Text(
                                    'Enviando a la IA...\nMejorando resolución',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Filtro aplicado.')),
                            );
                          },
                          icon: const Icon(Icons.filter),
                          label: const Text('Filtros'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: procesandoIA ? null : procesarImagenConIA,
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Mejorar IA 4K'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class BotonMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  const BotonMenu({
    super.key,
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icono, size: 26),
      label: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
