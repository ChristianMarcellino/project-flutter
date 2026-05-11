import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';


class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<String>? _image;
  List<Uint8List>? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  String? _category;
  String? _latitude;
  String? _longitude;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;


  Future<void> pickAndConvertThenCompressImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();

      var result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 80,
        minWidth: 1280,
        minHeight: 1280,
      );

      final encodedResult = base64Encode(result);

      setState(() {
        _image = encodedResult;
        _imageBytes = result;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
 
    );
  }
}