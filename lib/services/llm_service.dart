import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llm_server_dart/llm_server_dart.dart' as llm_server;
import 'package:mnemoszune/models/settings.dart';
import 'package:mnemoszune/providers/settings_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:langchain/langchain.dart';

class LLMService {
  final AppSettings settings;
  bool _isLocalServerManuallyStarted = false;
  bool _isEmbeddingServerManuallyStarted = false;
  final int _mainServerId = 0;
  final int _embeddingServerId = 1;
  final _mainHttpBaseUrl = 'http://localhost:8080/v1';
  final _embeddingHttpBaseUrl = 'http://localhost:8081/v1';

  LLMService(this.settings);

  Future<String> generateResponse(String prompt) async {
    try {
      switch (settings.llmProvider) {
        case LLMProvider.openai:
          if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
            throw Exception('OpenAI API key is missing');
          }
          // Use OpenAI API
          final client = _createOpenAIClient(
            'https://api.openai.com/v1',
            settings.openaiApiKey!,
          );
          return await client.complete(prompt);

        case LLMProvider.custom:
          if (settings.customApiUrl == null || settings.customApiUrl!.isEmpty) {
            throw Exception('Custom API URL is missing');
          }
          // Use custom OpenAI compatible API
          final client = _createOpenAIClient(
            settings.customApiUrl!,
            settings.openaiApiKey ?? '',
          );
          return await client.complete(prompt);

        case LLMProvider.local:
          if (!settings.isLocalServerRunning) {
            throw Exception(
              'Local model server is not running. Please start the server from Settings.',
            );
          }
          // Use the local server
          final client = _createLocalClient();
          return await client.complete(prompt);
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  OpenAIClient _createOpenAIClient(String endpoint, String apiKey) {
    return OpenAIClient(
      endpoint: endpoint,
      apiKey: apiKey,
      temperature: settings.temperature,
      maxTokens: settings.maxTokens,
    );
  }

  LocalClient _createLocalClient({bool isEmbeddingServer = false}) {
    final endpoint =
        isEmbeddingServer ? _embeddingHttpBaseUrl : _mainHttpBaseUrl;
    return LocalClient(
      endpoint: endpoint,
      temperature: settings.temperature,
      maxTokens: settings.maxTokens,
    );
  }

  // Start the main model server
  Future<void> startServer(String modelPath) async {
    if (_isLocalServerManuallyStarted) return;

    try {
      // Create server options with embedding flag
      final options = llm_server.ServerOptions(
        modelPath: modelPath,
        port: 8080,
        embedding:
            settings.embeddingEnabled && !settings.useSeperateEmbeddingModel,
      );

      // Start the server with the main server ID
      llm_server.startServer(options, _mainServerId);
      _isLocalServerManuallyStarted = true;
    } catch (e) {
      throw Exception('Failed to start server: ${e.toString()}');
    }
  }

  // Start a separate embedding model server
  Future<void> startEmbeddingServer(String modelPath) async {
    if (_isEmbeddingServerManuallyStarted) return;

    try {
      // Create server options with embedding explicitly enabled
      final options = llm_server.ServerOptions(
        modelPath: modelPath,
        port: 8081, // Different port for embedding server
        embedding: true,
      );

      // Start the server with the embedding server ID
      llm_server.startServer(options, _embeddingServerId);
      _isEmbeddingServerManuallyStarted = true;
    } catch (e) {
      throw Exception('Failed to start embedding server: ${e.toString()}');
    }
  }

  // Stop the main model server
  Future<void> stopServer() async {
    if (!_isLocalServerManuallyStarted) return;

    try {
      llm_server.stopServer(_mainServerId);
      _isLocalServerManuallyStarted = false;
    } catch (e) {
      throw Exception('Failed to stop server: ${e.toString()}');
    }
  }

  // Stop the embedding model server
  Future<void> stopEmbeddingServer() async {
    if (!_isEmbeddingServerManuallyStarted) return;

    try {
      llm_server.stopServer(_embeddingServerId);
      _isEmbeddingServerManuallyStarted = false;
    } catch (e) {
      throw Exception('Failed to stop embedding server: ${e.toString()}');
    }
  }

  // For cleanup when needed
  void dispose() {
    if (_isLocalServerManuallyStarted) {
      try {
        llm_server.stopServer(_mainServerId);
      } catch (_) {
        // Ignore errors during cleanup
      }
      _isLocalServerManuallyStarted = false;
    }

    if (_isEmbeddingServerManuallyStarted) {
      try {
        llm_server.stopServer(_embeddingServerId);
      } catch (_) {
        // Ignore errors during cleanup
      }
      _isEmbeddingServerManuallyStarted = false;
    }
  }
}

// Update OpenAIClient to use correct embeddings API
class OpenAIClient {
  final String endpoint;
  final String apiKey;
  final double temperature;
  final int maxTokens;

  OpenAIClient({
    required this.endpoint,
    required this.apiKey,
    required this.temperature,
    required this.maxTokens,
  });

  Future<String> complete(String prompt) async {
    // Implementation would use standard HTTP client to call the OpenAI API
    // This is a placeholder for the actual implementation
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return "Response for: $prompt (using OpenAI API)";
  }

  Future<List<List<double>>> embedMultiple(List<String> texts) async {
    final url = Uri.parse('$endpoint/embeddings');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'input': texts,
        'model':
            'text-embedding-ada-002', // Default OpenAI model for embeddings
        'encoding_format': 'float',
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] as List;

      // Extract embeddings from each result
      return data.map<List<double>>((item) {
        final embedding = item['embedding'] as List;
        return embedding.map<double>((value) => value as double).toList();
      }).toList();
    } else {
      throw Exception('Failed to generate embeddings: ${response.body}');
    }
  }
}

// Update LocalClient to use correct embeddings API
class LocalClient {
  final String endpoint;
  final double temperature;
  final int maxTokens;

  LocalClient({
    required this.endpoint,
    required this.temperature,
    required this.maxTokens,
  });

  Future<String> complete(String prompt) async {
    // Implementation would use standard HTTP client to call the local server
    // This is a placeholder for the actual implementation
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return "Response for: $prompt (using local server)";
  }

  Future<List<List<double>>> embedMultiple(List<String> texts) async {
    final url = Uri.parse('$endpoint/embeddings');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer no-key', // As shown in the example
      },
      body: jsonEncode({
        'input': texts,
        'model': 'GPT-4', // Placeholder model name
        'encoding_format': 'float',
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] as List;

      // Extract embeddings from each result
      return data.map<List<double>>((item) {
        final embedding = item['embedding'] as List;
        return embedding.map<double>((value) => value as double).toList();
      }).toList();
    } else {
      throw Exception('Failed to generate embeddings: ${response.body}');
    }
  }
}

// Provider for the LLM service
final llmServiceProvider = Provider<LLMService>((ref) {
  final settings = ref.watch(settingsProvider);

  // Cleanup when settings change or provider is disposed
  ref.onDispose(() {
    LLMService(settings).dispose();
  });

  return LLMService(settings);
});
