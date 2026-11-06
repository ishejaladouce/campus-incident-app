import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../utils/incident_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  String? _category;
  String _priority = 'Medium';
  File? _image;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Resize and compress so uploads are fast and light
      final picked = await _picker.pickImage(source: source, maxWidth: 1280, imageQuality: 70);
      if (picked != null) setState(() => _image = File(picked.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_image != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _image = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    final reporter = context.read<AuthProvider>().profile;
    if (reporter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load your profile. Please log out and log in again.')),
      );
      return;
    }

    final provider = context.read<IncidentProvider>();
    final success = await provider.submitIncident(
      title: _titleController.text,
      category: _category!,
      description: _descriptionController.text,
      location: _locationController.text,
      priority: _priority,
      image: _image,
      reporter: reporter,
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Report submitted! Staff will review it soon.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not submit the report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<IncidentProvider>().isSubmitting;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: IncidentCategory.all.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(CategoryStyle.icon(category), size: 20),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: isSubmitting ? null : (value) => setState(() => _category = value),
                  validator: (value) => value == null ? 'Please choose a category' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _titleController,
                  label: 'Short title',
                  icon: Icons.title,
                  maxLength: 100,
                  validator: (value) =>
                      Validators.textLength(value, fieldName: 'Title', min: 3, max: 100),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _locationController,
                  label: 'Location (e.g. Block B, 2nd floor)',
                  icon: Icons.place_outlined,
                  maxLength: 100,
                  validator: (value) =>
                      Validators.textLength(value, fieldName: 'Location', min: 2, max: 100),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Describe the problem',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  maxLength: 1000,
                  validator: (value) =>
                      Validators.textLength(value, fieldName: 'Description', min: 10, max: 1000),
                ),
                const SizedBox(height: 8),
                Text('Priority', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: IncidentPriority.all
                      .map((p) => ButtonSegment(value: p, label: Text(p)))
                      .toList(),
                  selected: {_priority},
                  onSelectionChanged: isSubmitting
                      ? null
                      : (selection) => setState(() => _priority = selection.first),
                ),
                const SizedBox(height: 16),
                Text('Photo (optional)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_image == null)
                  OutlinedButton.icon(
                    onPressed: isSubmitting ? null : _showImageOptions,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add a photo'),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Change photo',
                          onPressed: isSubmitting ? null : _showImageOptions,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Submit report', onPressed: _submit, isLoading: isSubmitting),
              ],
            ),
          ),
        ),
      ),
    );
  }
}