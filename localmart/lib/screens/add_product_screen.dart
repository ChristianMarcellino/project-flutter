import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:localmart/constants.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = "Electronics";
  final List<String> _images = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;
    final bytes = await image.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 50,
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );

    final base64 = base64Encode(compressed);

    setState(() {
      _images.add(base64);
    });
  }

  Future<void> _submit() async {
    final user = await UserService.getUser(authService.currentUser!.uid);

    final hasLocation =
        user?['locationName'] != null &&
        user!['locationName'].toString().isNotEmpty;

    if (!hasLocation) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete your location before posting a product.',
            ),
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate() || _images.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ProductService().addProduct(
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        images: _images,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text("Create Listing", style: AppTheme.h2),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close, color: AppTheme.textPrimary),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Product Images",
                      style: AppTheme.h2.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _buildImagePicker(),
                    const Text(
                      "Image must be less than 1 MB",
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      "Product Title",
                      _titleController,
                      "Enter product name",
                    ),
                    _buildTextField(
                      "Price (IDR)",
                      _priceController,
                      "0",
                      keyboardType: TextInputType.number,
                    ),
                    _buildDropdown(
                      "Category",
                      AppConstants.categories,
                      _selectedCategory,
                      (v) => setState(() => _selectedCategory = v!),
                    ),
                    _buildTextField(
                      "Description",
                      _descriptionController,
                      "Tell us more about your product",
                      maxLines: 5,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Post Listing",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppTheme.primary,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add Photo",
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final img = _images[index - 1];

          return Stack(
            children: [
              Container(
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    base64Decode(img),
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _images.removeAt(index - 1);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            dropdownColor: AppTheme.surface,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
