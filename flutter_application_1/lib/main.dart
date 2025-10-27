import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReceiptExtractor(),
    );
  }
}

class ReceiptExtractor extends StatefulWidget {
  const ReceiptExtractor({super.key});

  @override
  State<ReceiptExtractor> createState() => _ReceiptExtractorState();
}

class _ReceiptExtractorState extends State<ReceiptExtractor> {
  File? _selectedImage;
  String _result = "";
  bool _loading = false;

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
      await extractFile(_selectedImage!);
    } else {
      print('No image selected');
    }
  }

  Future<void> extractFile(File file) async {
    setState(() {
      _loading = true;
      _result = "";
    });

    final uri = Uri.parse('https://extraction-api.nanonets.com/extract');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer df6c60e7-aef2-11f0-a5c1-5ac389dc736a'
      ..fields['output_type'] = 'specified-json'
      ..fields['json_schema'] = ' {"invoice_number": "string", "date": "string", "store_name": "string", "items": [ { "name": "string", "price": "number" } ], "tax": "number", "total_amount": "number"} '
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      print('Uploading file: ${file.path}');
      final response = await request.send();
      final body = await response.stream.bytesToString();

      print('Status: ${response.statusCode}');
      print('Response body:\n$body');

      setState(() {
        _result = body;
        _loading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _loading = false;
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Docstrange dummy app")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 200),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Select Image"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Use Camera"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty
                        ? "Result will appear here."
                        : _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
