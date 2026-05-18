import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploaderWidget extends StatefulWidget {
  final Function(dynamic) onImageSelected;
  final dynamic initialImage;

  const ImageUploaderWidget({
    super.key,
    required this.onImageSelected,
    this.initialImage,
  });

  @override
  State<ImageUploaderWidget> createState() => _ImageUploaderWidgetState();
}

class _ImageUploaderWidgetState extends State<ImageUploaderWidget> {
  dynamic _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  @override
  void didUpdateWidget(ImageUploaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage != oldWidget.initialImage) {
      setState(() {
        _selectedImage = widget.initialImage;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    if (kIsWeb) {
      // Web: Use pickImage without path constraint
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        widget.onImageSelected(bytes);
        setState(() {
          _selectedImage = bytes;
        });
      }
    } else {
      // Mobile: Use File
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        widget.onImageSelected(file);
        setState(() {
          _selectedImage = file;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Tap to add image', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    if (kIsWeb) {
      // Web: Use Image.memory
      if (_selectedImage is List<int>) {
        return Image.memory(
          Uint8List.fromList(_selectedImage as List<int>),
          fit: BoxFit.cover,
        );
      }
    } else {
      // Mobile: Use Image.file
      if (_selectedImage is File) {
        return Image.file(
          _selectedImage as File,
          fit: BoxFit.cover,
        );
      }
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text('Tap to add image', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pet Image',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _showImageSourceDialog(context),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImagePreview(),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }
}
