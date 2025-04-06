import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mnemoszune/models/settings.dart';
import 'dart:convert';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  static const String _settingsKey = 'app_settings';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      try {
        // Parse as proper JSON instead of query string to handle complex types better
        final Map<String, dynamic> decodedJson = json.decode(settingsJson);
        state = AppSettings.fromJson(decodedJson);

        // If autostart is enabled for local model, start the server
        if (state.llmProvider == LLMProvider.local &&
            state.autoStartLocalServer &&
            state.localModelPath != null) {
          startLocalServer();
        }
      } catch (e) {
        // If there's an error in parsing, use default settings
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsMap = state.toJson();

    // Use proper JSON encoding to handle complex types
    await prefs.setString(_settingsKey, json.encode(settingsMap));
  }

  Future<void> toggleDarkMode() async {
    state = state.copyWith(darkMode: !state.darkMode);
    await _saveSettings();
  }

  Future<void> setFontFamily(String fontFamily) async {
    state = state.copyWith(fontFamily: fontFamily);
    await _saveSettings();
  }

  Future<void> setFontSize(double fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await _saveSettings();
  }

  Future<void> toggleNotifications() async {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
    await _saveSettings();
  }

  // New LLM settings methods
  Future<void> setLLMProvider(LLMProvider provider) async {
    state = state.copyWith(llmProvider: provider);
    await _saveSettings();
  }

  Future<void> setOpenAIApiKey(String apiKey) async {
    state = state.copyWith(openaiApiKey: apiKey);
    await _saveSettings();
  }

  Future<void> setCustomApiUrl(String apiUrl) async {
    state = state.copyWith(customApiUrl: apiUrl);
    await _saveSettings();
  }

  Future<void> setLocalModelPath(String modelPath) async {
    state = state.copyWith(localModelPath: modelPath);
    await _saveSettings();
  }

  Future<void> setTemperature(double temperature) async {
    state = state.copyWith(temperature: temperature);
    await _saveSettings();
  }

  Future<void> setMaxTokens(int maxTokens) async {
    state = state.copyWith(maxTokens: maxTokens);
    await _saveSettings();
  }

  // New LLM server control methods
  Future<void> setAutoStartLocalServer(bool autoStart) async {
    state = state.copyWith(autoStartLocalServer: autoStart);
    await _saveSettings();
  }

  Future<void> startLocalServer() async {
    if (state.llmProvider != LLMProvider.local ||
        state.localModelPath == null ||
        state.isLocalServerRunning) {
      return;
    }

    // Update state to indicate the server is running
    state = state.copyWith(isLocalServerRunning: true);
    // No need to save this runtime state
  }

  Future<void> stopLocalServer() async {
    if (!state.isLocalServerRunning) {
      return;
    }

    // Update state to indicate the server is stopped
    state = state.copyWith(isLocalServerRunning: false);
    // No need to save this runtime state
  }

  // Embedding settings methods
  Future<void> toggleEmbedding() async {
    state = state.copyWith(embeddingEnabled: !state.embeddingEnabled);
    await _saveSettings();
  }

  Future<void> setEmbeddingModelPath(String modelPath) async {
    state = state.copyWith(embeddingModelPath: modelPath);
    await _saveSettings();
  }

  Future<void> toggleSeparateEmbeddingModel() async {
    state = state.copyWith(
      useSeperateEmbeddingModel: !state.useSeperateEmbeddingModel,
    );
    await _saveSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});
