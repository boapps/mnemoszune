import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mnemoszune/providers/settings_provider.dart';
import 'package:mnemoszune/models/settings.dart';
import 'package:mnemoszune/services/llm_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        children: [
          // App appearance section
          const ListTile(title: Text('APPEARANCE'), tileColor: Colors.black12),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Change the app appearance'),
            value: settings.darkMode,
            onChanged: (_) {
              ref.read(settingsProvider.notifier).toggleDarkMode();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Text('${settings.fontSize.toInt()} sp'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: settings.fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                label: settings.fontSize.toInt().toString(),
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setFontSize(value);
                },
              ),
            ),
          ),

          const Divider(height: 32, thickness: 1),

          // Large Language Model settings section
          const ListTile(
            title: Text('LANGUAGE MODEL'),
            tileColor: Colors.black12,
          ),
          ListTile(
            title: const Text('LLM Provider'),
            subtitle: Text(_getLLMProviderLabel(settings.llmProvider)),
            onTap: () async {
              final result = await showDialog<LLMProvider>(
                context: context,
                builder:
                    (context) => _LLMProviderDialog(
                      currentProvider: settings.llmProvider,
                    ),
              );

              if (result != null) {
                // If changing away from local model, stop the server if it's running
                if (settings.llmProvider == LLMProvider.local &&
                    result != LLMProvider.local &&
                    settings.isLocalServerRunning) {
                  await ref.read(llmServiceProvider).stopServer();
                  ref.read(settingsProvider.notifier).stopLocalServer();
                }

                ref.read(settingsProvider.notifier).setLLMProvider(result);
              }
            },
          ),

          // Show appropriate fields based on selected provider
          if (settings.llmProvider == LLMProvider.openai)
            _buildApiKeyField(context, ref, settings),

          if (settings.llmProvider == LLMProvider.custom)
            _buildCustomApiUrlField(context, ref, settings),

          if (settings.llmProvider == LLMProvider.local)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocalModelField(context, ref, settings),

                // Server autostart option
                SwitchListTile(
                  title: const Text('Autostart Server'),
                  subtitle: const Text(
                    'Start the local model server when app opens',
                  ),
                  value: settings.autoStartLocalServer,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setAutoStartLocalServer(value);
                  },
                ),

                // Server control button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        settings.isLocalServerRunning
                            ? Icons.stop_circle
                            : Icons.play_circle,
                      ),
                      label: Text(
                        settings.isLocalServerRunning
                            ? 'Stop Server'
                            : 'Start Server',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            settings.isLocalServerRunning
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                      ),
                      onPressed:
                          settings.localModelPath == null
                              ? null // Disable if no model selected
                              : () async {
                                final llmService = ref.read(llmServiceProvider);
                                if (settings.isLocalServerRunning) {
                                  await llmService.stopServer();
                                  ref
                                      .read(settingsProvider.notifier)
                                      .stopLocalServer();
                                } else {
                                  await llmService.startServer(
                                    settings.localModelPath!,
                                  );
                                  ref
                                      .read(settingsProvider.notifier)
                                      .startLocalServer();
                                }
                              },
                    ),
                  ),
                ),

                // Server status indicator
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                settings.isLocalServerRunning
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          settings.isLocalServerRunning
                              ? 'Server Running'
                              : 'Server Stopped',
                          style: TextStyle(
                            color:
                                settings.isLocalServerRunning
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Common LLM settings
          const Divider(),
          ListTile(
            title: const Text('Temperature'),
            subtitle: Text('${settings.temperature.toStringAsFixed(1)}'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: settings.temperature,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: settings.temperature.toStringAsFixed(1),
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setTemperature(value);
                },
              ),
            ),
          ),

          const Divider(),
          ListTile(
            title: const Text('Max Tokens'),
            subtitle: Text('${settings.maxTokens}'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: settings.maxTokens.toDouble(),
                min: 256,
                max: 4096,
                divisions: 15,
                label: settings.maxTokens.toString(),
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setMaxTokens(value.toInt());
                },
              ),
            ),
          ),

          const Divider(height: 32, thickness: 1),

          // Embedding settings section
          const ListTile(
            title: Text('EMBEDDING SETTINGS'),
            tileColor: Colors.black12,
          ),

          // Enable/disable embeddings toggle
          SwitchListTile(
            title: const Text('Enable Embeddings'),
            subtitle: const Text(
              'Generate vector embeddings for semantic search',
            ),
            value: settings.embeddingEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).toggleEmbedding();

              // If we're changing embedding settings and local server is running,
              // it may need to be restarted
              if (settings.llmProvider == LLMProvider.local &&
                  settings.isLocalServerRunning) {
                _showRestartServerDialog(context, ref);
              }
            },
          ),

          // Only show additional embedding settings if embeddings are enabled
          if (settings.embeddingEnabled) ...[
            // Separate model toggle
            SwitchListTile(
              title: const Text('Use Separate Embedding Model'),
              subtitle: const Text(
                'Select a dedicated model optimized for embeddings',
              ),
              value: settings.useSeperateEmbeddingModel,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .toggleSeparateEmbeddingModel();

                if (settings.llmProvider == LLMProvider.local &&
                    settings.isLocalServerRunning) {
                  _showRestartServerDialog(context, ref);
                }
              },
            ),

            // Show embedding model selector only if using separate model
            if (settings.useSeperateEmbeddingModel)
              ListTile(
                title: const Text('Embedding Model'),
                subtitle: Text(
                  settings.embeddingModelPath != null
                      ? _getFileNameFromPath(settings.embeddingModelPath!)
                      : 'No embedding model selected',
                ),
                trailing: ElevatedButton(
                  child: const Text('Select'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['gguf'],
                    );

                    if (result != null && result.files.single.path != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setEmbeddingModelPath(result.files.single.path!);
                    }
                  },
                ),
              ),

            // Add embedding server controls if using local provider and separate model
            if (settings.llmProvider == LLMProvider.local &&
                settings.useSeperateEmbeddingModel)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      ref.watch(embeddingServerRunningProvider)
                          ? Icons.stop_circle
                          : Icons.play_circle,
                    ),
                    label: Text(
                      ref.watch(embeddingServerRunningProvider)
                          ? 'Stop Embedding Server'
                          : 'Start Embedding Server',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          ref.watch(embeddingServerRunningProvider)
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                    ),
                    onPressed:
                        settings.embeddingModelPath == null
                            ? null // Disable if no model selected
                            : () async {
                              final llmService = ref.read(llmServiceProvider);
                              if (ref.read(embeddingServerRunningProvider)) {
                                await llmService.stopEmbeddingServer();
                                ref
                                    .read(
                                      embeddingServerRunningProvider.notifier,
                                    )
                                    .state = false;
                              } else {
                                await llmService.startEmbeddingServer(
                                  settings.embeddingModelPath!,
                                );
                                ref
                                    .read(
                                      embeddingServerRunningProvider.notifier,
                                    )
                                    .state = true;
                              }
                            },
                  ),
                ),
              ),
          ],

          const Divider(height: 32, thickness: 1),

          // Notifications section
          const ListTile(
            title: Text('NOTIFICATIONS'),
            tileColor: Colors.black12,
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable or disable app notifications'),
            value: settings.notificationsEnabled,
            onChanged: (_) {
              ref.read(settingsProvider.notifier).toggleNotifications();
            },
          ),

          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.1',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getLLMProviderLabel(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.openai:
        return 'OpenAI API';
      case LLMProvider.custom:
        return 'Custom API Endpoint';
      case LLMProvider.local:
        return 'Local GGUF Model';
    }
  }

  Widget _buildApiKeyField(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final controller = TextEditingController(text: settings.openaiApiKey ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'OpenAI API Key',
          hintText: 'Enter your OpenAI API key',
          border: OutlineInputBorder(),
          helperText: 'Your API key is stored securely on your device only',
        ),
        obscureText: true,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setOpenAIApiKey(value);
        },
      ),
    );
  }

  Widget _buildCustomApiUrlField(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final controller = TextEditingController(text: settings.customApiUrl ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Custom API URL',
          hintText: 'Enter OpenAI-compatible API endpoint',
          border: OutlineInputBorder(),
          helperText: 'e.g., https://api.your-llm-provider.com/v1',
        ),
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setCustomApiUrl(value);
        },
      ),
    );
  }

  Widget _buildLocalModelField(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    return ListTile(
      title: const Text('Local GGUF Model'),
      subtitle: Text(
        settings.localModelPath != null
            ? _getFileNameFromPath(settings.localModelPath!)
            : 'No model selected',
      ),
      trailing: ElevatedButton(
        child: const Text('Select'),
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['gguf'],
          );

          if (result != null && result.files.single.path != null) {
            ref
                .read(settingsProvider.notifier)
                .setLocalModelPath(result.files.single.path!);
          }
        },
      ),
    );
  }

  String _getFileNameFromPath(String path) {
    return path.split('/').last;
  }

  // Helper method to show dialog for server restart
  void _showRestartServerDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final isEmbeddingServerRunning = ref.read(embeddingServerRunningProvider);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restart Required'),
            content: const Text(
              'The model server(s) need to be restarted for embedding '
              'changes to take effect.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('LATER'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final llmService = ref.read(llmServiceProvider);

                  // Restart main server if it was running
                  if (settings.isLocalServerRunning) {
                    await llmService.stopServer();
                    ref.read(settingsProvider.notifier).stopLocalServer();

                    if (settings.localModelPath != null) {
                      await llmService.startServer(settings.localModelPath!);
                      ref.read(settingsProvider.notifier).startLocalServer();
                    }
                  }

                  // Restart embedding server if it was running
                  if (isEmbeddingServerRunning) {
                    await llmService.stopEmbeddingServer();
                    ref.read(embeddingServerRunningProvider.notifier).state =
                        false;

                    if (settings.useSeperateEmbeddingModel &&
                        settings.embeddingModelPath != null) {
                      await llmService.startEmbeddingServer(
                        settings.embeddingModelPath!,
                      );
                      ref.read(embeddingServerRunningProvider.notifier).state =
                          true;
                    }
                  }
                },
                child: const Text('RESTART NOW'),
              ),
            ],
          ),
    );
  }
}

// Add a provider to track embedding server state
final embeddingServerRunningProvider = StateProvider<bool>((ref) => false);

class _LLMProviderDialog extends StatelessWidget {
  final LLMProvider currentProvider;

  const _LLMProviderDialog({required this.currentProvider});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select LLM Provider'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<LLMProvider>(
            title: const Text('OpenAI API'),
            subtitle: const Text('Use with your API key'),
            value: LLMProvider.openai,
            groupValue: currentProvider,
            onChanged: (value) => Navigator.of(context).pop(value),
          ),
          RadioListTile<LLMProvider>(
            title: const Text('Custom API Endpoint'),
            subtitle: const Text('OpenAI-compatible API'),
            value: LLMProvider.custom,
            groupValue: currentProvider,
            onChanged: (value) => Navigator.of(context).pop(value),
          ),
          RadioListTile<LLMProvider>(
            title: const Text('Local GGUF Model'),
            subtitle: const Text('Run models locally on device'),
            value: LLMProvider.local,
            groupValue: currentProvider,
            onChanged: (value) => Navigator.of(context).pop(value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}
