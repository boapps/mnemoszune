# mnemoszune

## Project Overview
Mnemoszune is a Flutter application designed to help users manage quizzes and class materials. Users can create subjects, add quizzes to each subject, and include multiple exercises within each quiz. The app utilizes Riverpod for state management and Drift for local database management.

## Features
- Create and manage subjects
- Add quizzes to each subject
- Include multiple exercises in each quiz (question-answer pairs or multiple choice)
- User-friendly interface for navigating between subjects, quizzes, and exercises

## Technologies Used
- Flutter: A UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
- Riverpod: A state management library for Flutter that provides a simple and robust way to manage application state.
- Drift: A persistence library for Flutter and Dart that allows for easy interaction with SQLite databases.

## Getting Started

### Prerequisites
- Flutter SDK installed on your machine
- Dart SDK (comes with Flutter)
- An IDE such as Android Studio or Visual Studio Code

### Installation
1. Clone the repository:
   ```
   git clone https://github.com/yourusername/mnemoszune.git
   ```
2. Navigate to the project directory:
   ```
   cd mnemoszune
   ```
3. Install the dependencies:
   ```
   flutter pub get
   ```

### Running the App
To run the app, use the following command:
```
flutter run
```

### Directory Structure
- `lib/main.dart`: Entry point of the application.
- `lib/models/`: Contains model classes for exercises, quizzes, and subjects.
- `lib/database/`: Contains database setup and table definitions.
- `lib/providers/`: Contains Riverpod providers for managing state.
- `lib/screens/`: Contains the UI screens for the application.
- `lib/widgets/`: Contains reusable widgets for the UI.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.