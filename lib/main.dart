import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(home: CanvaGrabApp(), debugShowCheckedModeBanner: false));

class CanvaGrabApp extends StatefulWidget {
  const CanvaGrabApp({super.key});
  @override
  State<CanvaGrabApp> createState() => _CanvaGrabAppState();
}

class _CanvaGrabAppState extends State<CanvaGrabApp> {
  File? _imageFile;
  Uint8List? _cleanedImage;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  List<TextBlock> _allBlocks = [];
  String _status = "Upload image";
  bool _loading = false;

  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  
  String? _foundReplacement;
  Rect? _replacementRect;
  Color _replacementBg = Colors.black;

  static const String _apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:10000/inpaint');

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _imageFile = File(file.path);
        _cleanedImage = null;
        _allBlocks = [];
        _foundReplacement = null;
        _replacementRect = null;
        _status = "Image uploaded";
      });
      final result = await _textRecognizer.processImage(InputImage.fromFilePath(file.path));
      setState(() { _allBlocks = result.blocks; });
    }
  }

  Future<void> _findAndReplace() async {
    String findText = _findController.text.trim();
    String replaceText = _replaceController.text.trim();
    if (_imageFile == null || findText.isEmpty || replaceText.isEmpty) return;

    setState(() { _loading = true; _status = "Finding '$findText'..."; });

    Rect? targetRect;
    Color bgColor = Colors.white;
    final bytes = await _imageFile!.readAsBytes();
    final decoded = img.decodeImage(bytes);

    for (var block in _allBlocks) {
      for (var line in block.lines) {
        if (line.text.toLowerCase().contains(findText.toLowerCase())) {
          targetRect = line.boundingBox;
          break;
        }
      }
      if (targetRect != null) break;
    }
    if (targetRect == null) { setState(() { _loading = false; _status = "Not found"; }); return; }

    final mask = img.Image(width: decoded!.width, height: decoded.height);
    img.fill(mask, color: img.ColorRgb8(0, 0, 0));
    img.fillRect(mask, x1: targetRect.left.toInt(), y1: targetRect.top.toInt(), x2: targetRect.right.toInt(), y2: targetRect.bottom.toInt(), color: img.ColorRgb8(255, 255, 255));
    final maskBytes = Uint8List.fromList(img.encodePng(mask));
    
    final cleaned = await _callMyAPI(bytes, maskBytes);
    
    setState(() {
      _cleanedImage = cleaned;
      _foundReplacement = replaceText;
      _replacementRect = targetRect;
      _replacementBg = bgColor;
      _loading = false;
      _status = cleaned != null ? "Done!" : "API failed";
    });
  }

  Future<Uint8List?> _callMyAPI(Uint8List imgB, Uint8List maskB) async {
    try {
      var req = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      req.fields['prompt'] = 'clean seamless background, no text';
      req.files.add(http.MultipartFile.fromBytes('image', imgB, filename: 'image.png'));
      req.files.add(http.MultipartFile.fromBytes('mask', maskB, filename: 'mask.png'));
      var streamed = await req.send();
      var res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) return res.bodyBytes;
      return null;
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_status)),
      body: Column(children: [
        Expanded(child: Center(child: _loading ? CircularProgressIndicator() : _imageFile == null ? Text("Upload image") : _cleanedImage != null ? Image.memory(_cleanedImage!) : Image.file(_imageFile!))),
        Padding(padding: EdgeInsets.all(12), child: Column(children: [
          TextField(controller: _findController, decoration: InputDecoration(labelText: "Text to find", border: OutlineInputBorder())),
          SizedBox(height: 8),
          TextField(controller: _replaceController, decoration: InputDecoration(labelText: "Replace with", border: OutlineInputBorder())),
          SizedBox(height: 8),
          ElevatedButton(onPressed: _findAndReplace, child: Text("REMOVE & REPLACE"))
        ]))
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _pickImage, child: Icon(Icons.add_a_photo)),
    );
  }
}