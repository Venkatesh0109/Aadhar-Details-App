import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ml_text_recognition/image_preview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextRecognizer textRecognizer;
  late ImagePicker imagePicker;

  String? pickedImagePath;
  String recognizedText = "";

  bool isRecognizing = false;

  @override
  void initState() {
    super.initState();

    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    imagePicker = ImagePicker();
  }

  void _pickImageAndProcess({required ImageSource source}) async {
  final pickedImage = await imagePicker.pickImage(source: source);

  if (pickedImage == null) {
    return;
  }

  setState(() {
    pickedImagePath = pickedImage.path;
    isRecognizing = true;
  });

  try {
    final inputImage = InputImage.fromFilePath(pickedImage.path);
    final RecognizedText recognisedText = await textRecognizer.processImage(inputImage);

    recognizedText = "";

    // Regular expression to match exactly 12-digit Aadhaar numbers
    final RegExp aadhaarRegex = RegExp(r'\b\d{4} \d{4} \d{4}\b'); 

    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        final matches = aadhaarRegex.allMatches(line.text);
        for (var match in matches) {
          recognizedText += "${match.group(0)}\n"; // Store only Aadhaar number
        }
      }
    }

    if (recognizedText.isEmpty) {
      recognizedText = "No valid Aadhaar number found";
    }
  } catch (e) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error recognizing text: $e'),
      ),
    );
  } finally {
    setState(() {
      isRecognizing = false;
    });
  }
}


  void _chooseImageSourceModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndProcess(source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndProcess(source: ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyTextToClipboard() async {
    if (recognizedText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: recognizedText));
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Text Recognition'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ImagePreview(imagePath: pickedImagePath),
            ),
            ElevatedButton(
              onPressed: isRecognizing ? null : _chooseImageSourceModal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pick an image'),
                  if (isRecognizing) ...[
                    const SizedBox(width: 20),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recognized Text",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 16,
                    ),
                    onPressed: _copyTextToClipboard,
                  ),
                ],
              ),
            ),
            if (!isRecognizing) ...[
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Flexible(
                          child: SelectableText(
                            recognizedText.isEmpty
                                ? "No valid Aadhaar number found"
                                : recognizedText,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold, // Make Aadhaar number bold
                              fontSize: 18, // Increase font size
                              color: Colors.blue, // Change color if needed
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
