import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_openai/langchain_openai.dart';
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

  ChatOpenAI getLLM() {
    if (settings.llmProvider == LLMProvider.local) {
      return ChatOpenAI(
        apiKey: settings.openaiApiKey,
        baseUrl: _mainHttpBaseUrl,
      );
    } else if (settings.llmProvider == LLMProvider.openai) {
      return ChatOpenAI(
        apiKey: settings.openaiApiKey,
        baseUrl: 'https://api.openai.com/v1',
      );
    } else if (settings.llmProvider == LLMProvider.custom) {
      return ChatOpenAI(
        apiKey: settings.openaiApiKey,
        baseUrl: settings.customApiUrl ?? 'https://api.openai.com/v1',
      );
    } else {
      throw Exception('Unsupported LLM provider');
    }
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

// Provider for the LLM service
final llmServiceProvider = Provider<LLMService>((ref) {
  final settings = ref.watch(settingsProvider);

  // Cleanup when settings change or provider is disposed
  ref.onDispose(() {
    LLMService(settings).dispose();
  });

  return LLMService(settings);
});
