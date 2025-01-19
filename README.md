# iPARK - Intelligent Parking Recommendation System (Mobile App)

[![Flutter](https://img.shields.io/badge/Flutter-Framework-blue)](https://flutter.dev/)  
iPARK is a smart parking recommendation system designed to make parking efficient and hassle-free for users. This repository contains the source code for the **iPARK mobile application**, developed using Dart and Flutter. The app leverages personalized user preferences, real-time data, and advanced algorithms to recommend the most suitable parking spaces, including features for individuals with special requirements.

## Features
![image](https://github.com/user-attachments/assets/c9131f83-221b-48a4-a7ac-c112e9f3adff)


- **Personalized Parking Recommendations**  
  Get parking suggestions based on your preferences, such as EV charging, wheelchair access, covered parking, and more.

- **Real-Time Space Availability**  
  Check whether parking spaces are occupied or available instantly.

- **Parking Lot Navigation**  
  Browse through parking locations organized by state, district, and lot.

- **Interactive UI**  
  Seamless and intuitive user experience with a focus on accessibility and ease of navigation.

- **Specialized Parking Options**  
  Recommendations for users with disabilities, EV vehicles, or family parking needs.

## Tech Stack

- **Frontend Framework**: Flutter (Dart)
- **Backend**: Flask REST API (Deployed separately at [iPARK Backend Repository](https://github.com/ImanZulhakim/iPark-Backend))  
  *(Requires Flask and MySQL for database integration.)*

## Screenshots

*Add screenshots here to showcase your app (e.g., home screen, recommendation screen, parking details screen).*

## Getting Started

### Prerequisites

- Flutter SDK installed ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio or VS Code with Flutter extension
- A connected MySQL database for real-time updates (Backend required: [iPARK Backend](https://github.com/ImanZulhakim/iPark-Backend))

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ImanZulhakim/iPark.git
   cd iPark
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure the API endpoint**:
   - Open the `lib/constants/api.dart` file (or equivalent configuration file).
   - Replace the base URL with your backend API endpoint:
     ```dart
     const String BASE_URL = "http://<your-backend-host>:5000";
     ```

4. **Run the app**:
   - Connect an Android or iOS device.
   - Use the Flutter CLI to launch the app:
     ```bash
     flutter run
     ```

### Building APK/IPA

- **Build APK**:
  ```bash
  flutter build apk --release
  ```
  The APK will be available in the `build/app/outputs/flutter-apk` directory.

- **Build IPA** (macOS required for iOS):
  ```bash
  flutter build ios --release
  ```

## API Endpoints (Backend Integration)

- **Parking Recommendation**:
  - **Endpoint**: `/recommend-parking`
  - **Method**: `POST`
  - **Payload**:
    ```json
    {
      "userID": "12345",
      "lotID": "56789"
    }
    ```
  - **Response**:
    ```json
    {
      "status": "success",
      "parkingSpaceID": "A1"
    }
    ```

## Folder Structure

```plaintext
iPark/
│
├── lib/
│   ├── models/          # Data models (e.g., parking space, user preferences)
│   ├── screens/         # UI screens (e.g., home, recommendations)
│   ├── services/        # API integration and data handling
│   ├── utils/           # Utility functions and helpers
│   ├── constants/       # App-wide constants (e.g., API endpoints, styles)
│   └── main.dart        # App entry point
│
├── assets/              # Static assets (e.g., images, icons)
├── pubspec.yaml         # Flutter dependencies and configurations
└── README.md            # Project README file
```

## Contributing

Contributions are welcome! Follow these steps to contribute:
1. Fork the repository.
2. Create a new branch (`git checkout -b feature/YourFeature`).
3. Commit your changes (`git commit -m 'Add your feature'`).
4. Push to the branch (`git push origin feature/YourFeature`).
5. Open a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
