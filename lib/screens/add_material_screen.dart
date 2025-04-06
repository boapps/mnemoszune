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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        if (_titleController.text.isEmpty) {
          _titleController.text = _selectedFileName ?? '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Selected file: $_selectedFileName'),
              ],

              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed:
                    (_selectedFilePath == null)
                        ? null
                        : () async {
                          if (_formKey.currentState!.validate()) {
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
                    ref.watch(materialNotifierProvider).isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save Material'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
