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
import 'package:mnemoszune/services/vector_service.dart';
import 'package:path_provider/path_provider.dart';

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isAppReady = false;

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure the app is ready before processing deeplinks
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _isAppReady = true;
      });
      _initAppLinks();
    });
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
      // Only attempt to show dialog if app is ready
      if (_isAppReady && _navigatorKey.currentContext != null) {
        showDialog(
          context: _navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  Text('Processing Moodle data...'),
                ],
              ),
            );
          },
        );
      }

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

            // Process data asynchronously
            Future.wait([loginToMoodle(token), processCourses(token)])
                .then((_) {
                  // Close the dialog when processing is complete
                  if (_isAppReady && _navigatorKey.currentState != null) {
                    Navigator.of(
                      _navigatorKey.currentContext!,
                      rootNavigator: true,
                    ).pop();
                  }
                })
                .catchError((error) {
                  // Close dialog and show error if needed
                  if (_isAppReady && _navigatorKey.currentState != null) {
                    Navigator.of(
                      _navigatorKey.currentContext!,
                      rootNavigator: true,
                    ).pop();
                    _showErrorDialog('Error processing Moodle data: $error');
                  }
                });
          } else {
            print('Token string does not have expected format: $tokenString');
            if (_isAppReady && _navigatorKey.currentState != null) {
              Navigator.of(
                _navigatorKey.currentContext!,
                rootNavigator: true,
              ).pop();
              _showErrorDialog('Invalid token format');
            }
          }
        } else {
          print('URL does not contain a token parameter: $uri');
          if (_isAppReady && _navigatorKey.currentState != null) {
            Navigator.of(
              _navigatorKey.currentContext!,
              rootNavigator: true,
            ).pop();
            _showErrorDialog('No token found in the link');
          }
        }
      } catch (e) {
        print('Error processing app link: $e');
        // Close dialog and show error
        if (_isAppReady && _navigatorKey.currentState != null) {
          Navigator.of(
            _navigatorKey.currentContext!,
            rootNavigator: true,
          ).pop();
          _showErrorDialog('Error processing link: $e');
        }
      }
    }
  }

  // Helper method to show error dialog
  void _showErrorDialog(String message) {
    if (_isAppReady && _navigatorKey.currentContext != null) {
      showDialog(
        context: _navigatorKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Update these methods to return Future for proper async handling
  Future<void> loginToMoodle(String token) async {
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

  Future<void> processCourses(String token) async {
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
    await _saveCoursesToDatabase(visibleCourses, token);
  }

  void saveCourseContent(String token, int courseId, int subjectId) async {
    final params = {
      'wstoken': token,
      'wsfunction': 'core_course_get_contents',
      'moodlewsrestformat': 'json',
      'courseid': courseId.toString(),
    };
    final response = await http.post(
      Uri.parse('https://edu.vik.bme.hu/webservice/rest/server.php'),
      body: params,
    );
    List<dynamic> data = jsonDecode(response.body);
    print(data);

    final database = ref.watch(databaseProvider);
    final vectorServiceAsync = ref.read(vectorServiceProvider);
    if (!vectorServiceAsync.hasValue) {
      throw Exception("Vector service is not ready yet");
    }

    final vectorService = vectorServiceAsync.value!;

    // Process each section
    for (var section in data) {
      final sectionName = section['name'];
      final sectionId = section['id'];
      final isVisible = section['visible'] == 1;

      if (!isVisible) continue;

      print('Processing section: $sectionName');

      // Process modules within this section
      if (section['modules'] != null) {
        for (var module in section['modules']) {
          final moduleName = module['name'];
          final moduleId = module['id'];
          final moduleType = module['modname'];
          final moduleUrl = module['url'];
          final isModuleVisible =
              module['visible'] == 1 && module['uservisible'] == true;

          if (!isModuleVisible) continue;

          print('  - Module: $moduleName ($moduleType)');

          // Process content files if they exist
          if (module['contents'] != null) {
            for (var content in module['contents']) {
              final fileUrl = content['fileurl'];
              final fileName = content['filename'];
              final filePath = content['filepath'];

              if (content['type'] != 'file') continue;
              if (fileUrl == null || fileName == null) continue;
              if (fileUrl.isEmpty || fileName.isEmpty) continue;

              print('    * Content: $fileName ($fileUrl)');

              // Download the file
              final response = await http.get(
                Uri.parse(fileUrl + "&token=$token"),
              );
              if (response.statusCode == 200) {
                // Get app document directory path
                final documentsDir = await getApplicationSupportDirectory();
                final filePath = '${documentsDir.path}/$fileName';

                // Save the file locally
                final localFile = File(filePath);
                await localFile.writeAsBytes(response.bodyBytes);
                print('    * File saved to app directory: $filePath');

                // add file to Materials table

                final materialEntry = MaterialsCompanion(
                  title: drift.Value(fileName),
                  description: drift.Value(''),
                  subjectId: drift.Value(subjectId),
                  filePath: drift.Value(filePath),
                  createdAt: drift.Value(DateTime.now()),
                );

                final materialId = await database.insertMaterial(materialEntry);
                try {
                  await vectorService.processAndStoreDocument(
                    materialId,
                    filePath,
                  );

                  // Update material to mark it as vectorized
                  await database.markMaterialAsVectorized(materialId);
                } catch (e, s) {
                  // Log the error but don't fail the whole operation
                  print('Error processing document for vector storage: $e');
                  print('Stack trace: $s');
                  // Material is still added but not vectorized
                }
              } else {
                print('    * Failed to download file: $fileName');
              }

              // TODO: Save content reference to database
            }
          }
        }
      }
    }
  }

  Future<void> _saveCoursesToDatabase(
    List<dynamic> courses,
    String token,
  ) async {
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
          final subjectId = await database.insertSubject(subjectEntry);

          saveCourseContent(token, course['id'], subjectId);

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
      navigatorKey: _navigatorKey,
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
