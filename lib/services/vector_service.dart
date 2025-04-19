import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_community/langchain_community.dart';
import 'package:mnemoszune/models/settings.dart';
import 'package:mnemoszune/providers/settings_provider.dart';
import 'package:mnemoszune/services/llm_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class VectorService {
  final LLMService llmService;
  final AppSettings settings;
  late ObjectBoxVectorStore _vectorStore;
  final _textSplitter = RecursiveCharacterTextSplitter(
    chunkSize: 400,
    chunkOverlap: 20,
  );

  VectorService({required this.llmService, required this.settings}) {
    _initializeVectorStore();
  }

  void _initializeVectorStore() {
    // Create an Embeddings implementation based on the current settings
    final embeddings = OpenAIEmbeddings(
      apiKey: settings.openaiApiKey,
      baseUrl:
          settings.useSeperateEmbeddingModel
              ? 'http://localhost:8081/v1'
              : 'https://api.openai.com/v1',
    );
    // Initialize memory vector store with the embeddings
    getApplicationSupportDirectory().then((directory) {
      _vectorStore = ObjectBoxVectorStore(
        embeddings: embeddings,
        dimensions: 512,
        directory: '$directory/vector_store',
      );
    });
  }

  Future<void> processAndStoreDocument(int materialId, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    // Extract text from document based on file type
    List<Document> documents = await _extractTextFromFile(file);
    // Create Document with metadata

    await _vectorStore.addDocuments(documents: documents);
  }

  Future<List<Document>> _txtToDocuments(String filePath) async {
    print('Extracting text from file: $filePath');

    var loader = TextLoader(filePath);
    List<Document> documents = await loader.load();

    List<Document> docs = _textSplitter.splitDocuments(documents);

    return docs;
  }

  Future<List<Document>> _pdfToDocuments(String filePath) async {
    print('Extracting text from PDF: $filePath');

    //Load an existing PDF document.
    PdfDocument document = PdfDocument(
      inputBytes: File(filePath).readAsBytesSync(),
    );
    //Extract the text from page 1.
    List<Document> docs = [];
    for (int i = 0; i < document.pages.count; i++) {
      String text = PdfTextExtractor(
        document,
      ).extractText(startPageIndex: i, endPageIndex: i);
      docs.add(
        Document(
          pageContent: text,
          metadata: {
            'page': i,
            'materialId': 0, // TODO
          },
        ),
      );
    }
    document.dispose();
    List<Document> splitDocs = _textSplitter.splitDocuments(docs);

    return splitDocs;
  }

  Future<List<Document>> _extractTextFromFile(File file) async {
    final extension = path.extension(file.path).toLowerCase();

    // Basic text extraction based on file type
    // In a real implementation, you would use specialized libraries for PDF, DOCX, etc.
    switch (extension) {
      case '.txt':
        return await _txtToDocuments(file.path);
      case '.md':
        return await _txtToDocuments(file.path);
      case '.pdf':
        return await _pdfToDocuments(file.path);
      default:
        try {
          return await _txtToDocuments(file.path);
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
