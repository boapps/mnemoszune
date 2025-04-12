import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mnemoszune/providers/material_provider.dart';
import 'dart:io';

class AddMaterialScreen extends ConsumerStatefulWidget {
  final int subjectId;

  const AddMaterialScreen({super.key, required this.subjectId});

  @override
  ConsumerState<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends ConsumerState<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isTextExtractable = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final path = result.files.single.path;
      final name = result.files.single.name;

      // Check if file is likely to be text-extractable
      final extension = path?.split('.').last.toLowerCase();
      final extractableExtensions = [
        'txt',
        'md',
        'pdf',
        'doc',
        'docx',
        'html',
        'rtf',
      ];

      setState(() {
        _selectedFilePath = path;
        _selectedFileName = name;
        _isTextExtractable = extractableExtensions.contains(extension);

        if (_titleController.text.isEmpty && name != null) {
          _titleController.text = name;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(materialNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Material'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Material Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),

              // File selection
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Select File'),
              ),
              if (_selectedFileName != null) ...[
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(child: Text('Selected file: $_selectedFileName')),
                    if (!_isTextExtractable)
                      const Tooltip(
                        message: 'This file type may not be searchable',
                        child: Icon(Icons.info_outline, color: Colors.amber),
                      ),
                  ],
                ),
              ],

              if (_isTextExtractable && _selectedFilePath != null) ...[
                const SizedBox(height: 8.0),
                const Text(
                  'This material will be processed for searchable content. This might take a moment.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],

              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed:
                    (_selectedFilePath == null || isLoading)
                        ? null
                        : () async {
                          if (_formKey.currentState!.validate()) {
                            // Show progress dialog for long vectorization processes
                            await ref
                                .read(materialNotifierProvider.notifier)
                                .addMaterial(
                                  _titleController.text,
                                  _descriptionController.text.isEmpty
                                      ? null
                                      : _descriptionController.text,
                                  widget.subjectId,
                                  _selectedFilePath!,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child:
                    isLoading
                        ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Processing...'),
                          ],
                        )
                        : const Text('Save Material'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
