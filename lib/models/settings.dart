class AppSettings {
  final bool darkMode;
  final String fontFamily;
  final double fontSize;
  final bool notificationsEnabled;

  // LLM settings
  final LLMProvider llmProvider;
  final String? openaiApiKey;
  final String? customApiUrl;
  final String? localModelPath;
  final double temperature;
  final int maxTokens;
  // Local model server settings
  final bool autoStartLocalServer;
  final bool isLocalServerRunning;
  // Embedding settings
  final bool embeddingEnabled;
  final String? embeddingModelPath;
  final bool useSeperateEmbeddingModel;

  const AppSettings({
    this.darkMode = false,
    this.fontFamily = 'Roboto',
    this.fontSize = 16.0,
    this.notificationsEnabled = true,

    // LLM default settings
    this.llmProvider = LLMProvider.openai,
    this.openaiApiKey,
    this.customApiUrl,
    this.localModelPath,
    this.temperature = 0.7,
    this.maxTokens = 1024,
    // Local model server settings
    this.autoStartLocalServer = false,
    this.isLocalServerRunning = false,
    // Embedding settings
    this.embeddingEnabled = false,
    this.embeddingModelPath,
    this.useSeperateEmbeddingModel = false,
  });

  AppSettings copyWith({
    bool? darkMode,
    String? fontFamily,
    double? fontSize,
    bool? notificationsEnabled,
    LLMProvider? llmProvider,
    String? openaiApiKey,
    String? customApiUrl,
    String? localModelPath,
    double? temperature,
    int? maxTokens,
    bool? autoStartLocalServer,
    bool? isLocalServerRunning,
    bool? embeddingEnabled,
    String? embeddingModelPath,
    bool? useSeperateEmbeddingModel,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      llmProvider: llmProvider ?? this.llmProvider,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      customApiUrl: customApiUrl ?? this.customApiUrl,
      localModelPath: localModelPath ?? this.localModelPath,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      autoStartLocalServer: autoStartLocalServer ?? this.autoStartLocalServer,
      isLocalServerRunning: isLocalServerRunning ?? this.isLocalServerRunning,
      embeddingEnabled: embeddingEnabled ?? this.embeddingEnabled,
      embeddingModelPath: embeddingModelPath ?? this.embeddingModelPath,
      useSeperateEmbeddingModel:
          useSeperateEmbeddingModel ?? this.useSeperateEmbeddingModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'notificationsEnabled': notificationsEnabled,
      'llmProvider': llmProvider.name,
      'openaiApiKey': openaiApiKey,
      'customApiUrl': customApiUrl,
      'localModelPath': localModelPath,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'autoStartLocalServer': autoStartLocalServer,
      // We don't save isLocalServerRunning state to persistent storage
      // as it's a runtime value that should be false when app starts
      'embeddingEnabled': embeddingEnabled,
      'embeddingModelPath': embeddingModelPath,
      'useSeperateEmbeddingModel': useSeperateEmbeddingModel,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      darkMode: json['darkMode'] as bool? ?? false,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      fontSize: json['fontSize'] as double? ?? 16.0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      llmProvider:
          _getLLMProviderFromString(json['llmProvider'] as String?) ??
          LLMProvider.openai,
      openaiApiKey: json['openaiApiKey'] as String?,
      customApiUrl: json['customApiUrl'] as String?,
      localModelPath: json['localModelPath'] as String?,
      temperature: json['temperature'] as double? ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 1024,
      autoStartLocalServer: json['autoStartLocalServer'] as bool? ?? false,
      // Server always starts in stopped state
      isLocalServerRunning: false,
      embeddingEnabled: json['embeddingEnabled'] as bool? ?? false,
      embeddingModelPath: json['embeddingModelPath'] as String?,
      useSeperateEmbeddingModel:
          json['useSeperateEmbeddingModel'] as bool? ?? false,
    );
  }

  static LLMProvider? _getLLMProviderFromString(String? value) {
    if (value == null) return null;
    return LLMProvider.values.firstWhere(
      (element) => element.name == value,
      orElse: () => LLMProvider.openai,
    );
  }
}

enum LLMProvider { openai, custom, local }
