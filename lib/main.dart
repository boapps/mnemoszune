import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/providers/database_provider.dart';
import 'package:mnemoszune/screens/home_screen.dart';
import 'package:mnemoszune/providers/settings_provider.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'package:mnemoszune/database/database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  runApp(const ProviderScope(child: MnemoszuneApp()));
}

class MnemoszuneApp extends ConsumerStatefulWidget {
  const MnemoszuneApp({super.key});

  @override
  ConsumerState<MnemoszuneApp> createState() => _MnemoszuneAppState();
}

class _MnemoszuneAppState extends ConsumerState<MnemoszuneApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  Future<void> _initAppLinks() async {
    // Get the initial app link if the app was launched from a link
    final appLink = await _appLinks.getInitialAppLinkString();

    if (appLink != null) {
      _handleAppLink(appLink);
    }

    // Listen for app links while the app is running
    _appLinks.allStringLinkStream.listen((uri) {
      _handleAppLink(uri);
    });
  }

  void _handleAppLink(String uri) {
    print('Received app link: $uri');
    if (uri.startsWith('mnemoszune://')) {
      try {
        // Check if the URL contains a token parameter
        if (uri.contains('token=')) {
          // Get everything after "token="
          final base64Data = uri.split('token=')[1];

          // Proper Base64 padding check
          String paddedBase64 = base64Data;
          while (paddedBase64.length % 4 != 0) {
            paddedBase64 += '=';
          }

          final decodedData = base64Decode(paddedBase64);
          final tokenString = utf8.decode(decodedData);

          // Split and extract token safely
          if (tokenString.contains(':::')) {
            final token = tokenString.split(':::')[1];
            print('Successfully extracted token: $token');

            loginToMoodle(token);
            getCourses(token);

            // TODO: Store the token for authentication or navigate to login screen
          } else {
            print('Token string does not have expected format: $tokenString');
          }
        } else {
          print('URL does not contain a token parameter: $uri');
        }
      } catch (e) {
        print('Error processing app link: $e');
        // Continue app execution even if link processing fails
      }

      // You can parse the URI further and navigate to appropriate screens
      // For example:
      // final path = uri.path;
      // final queryParams = uri.queryParameters;
      // Navigate based on these values
    }
  }

  void loginToMoodle(String token) async {
    final params = {
      'wstoken': token,
      'wsfunction': 'core_webservice_get_site_info',
      'moodlewsrestformat': 'json',
    };
    final response = await http.post(
      Uri.parse('https://edu.vik.bme.hu/webservice/rest/server.php'),
      body: params,
    );
    // write response.body to file
    final data = jsonDecode(response.body);
    final userId = data['userid'];
  }

  void getCourses(String token) async {
    final params = {
      'wstoken': token,
      'wsfunction': 'core_course_get_courses_by_field',
      'moodlewsrestformat': 'json',
    };
    final response = await http.post(
      Uri.parse('https://edu.vik.bme.hu/webservice/rest/server.php'),
      body: params,
    );
    final data = jsonDecode(response.body);
    final courses = data['courses'];

    final visibleCourses =
        courses.where((course) => course['visible'] == 1).toList();
    print(visibleCourses);

    // Save visible courses to the database
    await _saveCoursesToDatabase(visibleCourses);
  }

  Future<void> _saveCoursesToDatabase(List<dynamic> courses) async {
    final database = ref.watch(databaseProvider);
    int newSubjectsAdded = 0;
    int existingSubjectsNumber = 0;

    for (final course in courses) {
      try {
        final courseName = course['fullname'];

        // Check if a subject with this name already exists
        final existingSubjects = await database.getSubjectsByName(courseName);

        if (existingSubjects.isEmpty) {
          // Create a new Subject entry from the course data
          final subjectEntry = SubjectsCompanion(
            name: drift.Value(courseName),
            description: drift.Value(course['summary'] ?? ''),
            createdAt: drift.Value(DateTime.now()),
          );

          // Insert the subject into the database
          await database.insertSubject(subjectEntry);
          newSubjectsAdded++;
        } else {
          existingSubjectsNumber++;
        }
      } catch (e) {
        print('Error processing course: $e');
      }
    }

    print('Saved $newSubjectsAdded new courses to database as subjects');
    print('Skipped $existingSubjectsNumber courses that already existed');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Mnemoszune',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: settings.darkMode ? Brightness.dark : Brightness.light,
        ),
        fontFamily: settings.fontFamily,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: settings.fontSize),
          bodyMedium: TextStyle(fontSize: settings.fontSize - 2),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
