import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_chroma/langchain_chroma.dart';
import 'package:mnemoszune/models/settings.dart';
import 'package:mnemoszune/providers/settings_provider.dart';
import 'package:mnemoszune/services/llm_service.dart';
import 'package:path/path.dart' as path;

class VectorService {
  final LLMService llmService;
  final AppSettings settings;
  late Chroma _vectorStore;

  VectorService({required this.llmService, required this.settings}) {
    _initializeVectorStore();
  }

  void _initializeVectorStore() {
    // Create an Embeddings implementation based on the current settings
    final embeddings = OpenAIEmbeddings(
      apiKey: settings.openaiApiKey,
      baseUrl:
          settings.useSeperateEmbeddingModel
              ? 'http://localhost:8081'
              : 'https://api.openai.com/v1',
    );
    // Initialize memory vector store with the embeddings
    _vectorStore = Chroma(embeddings: embeddings);
  }

  Future<void> processAndStoreDocument(int materialId, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    // Extract text from document based on file type
    final text = await _extractTextFromFile(file);
    if (text.isEmpty) {
      throw Exception('Could not extract text from file');
    }

    // Create Document with metadata
    final document = Document(
      pageContent: text,
      metadata: {'materialId': materialId, 'filePath': filePath},
    );

    await _vectorStore.addDocuments(documents: [document]);
  }

  Future<String> _extractTextFromFile(File file) async {
    final extension = path.extension(file.path).toLowerCase();

    // Basic text extraction based on file type
    // In a real implementation, you would use specialized libraries for PDF, DOCX, etc.
    switch (extension) {
      case '.txt':
        return await file.readAsString();
      case '.md':
        return await file.readAsString();
      // Add more file type handlers as needed
      default:
        // For this example, just try to read as text
        // In a real app, you'd need proper extractors for various file types
        try {
          return await file.readAsString();
        } catch (e) {
          throw Exception('Unsupported file type: $extension');
        }
    }
  }

  Future<List<Document>> similaritySearch(String query, {int k = 4}) async {
    return await _vectorStore.similaritySearch(
      query: query,
      config: VectorStoreSimilaritySearch(k: k),
    );
  }
}

// Provider for the vector service
final vectorServiceProvider = Provider<VectorService>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final settings = ref.watch(settingsProvider);

  return VectorService(llmService: llmService, settings: settings);
});
