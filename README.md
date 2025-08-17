# Clinic Token Generator

A Flutter app for generating patient queue tokens in a clinic. The app automatically resets token numbers daily and stores all data locally using SharedPreferences.

## Features

- **Doctor Management**: Add, view, and delete doctors with their specializations
- **Daily Token Generation**: Automatically resets token numbers at midnight
- **Local Storage**: All data is stored locally using SharedPreferences (no backend required)
- **Token History**: Keeps track of generated tokens with timestamps
- **Modern UI**: Clean, intuitive interface with Material Design 3
- **Cross-Platform**: Works on both Android and iOS

## How It Works

1. **Daily Reset**: The app checks if the current date is different from the last token generation date
2. **Token Increment**: If it's the same day, tokens increment sequentially
3. **Automatic Reset**: If it's a new day, the token counter resets to 1
4. **Local Persistence**: All data is stored locally and persists between app sessions

## App Flow

1. **Setup**: Clinic staff opens the app and adds doctors
2. **Daily Operation**: Staff generates tokens for patients throughout the day
3. **Automatic Reset**: At midnight, all token counters automatically reset
4. **Data Persistence**: All information is saved locally and available offline

## Technical Details

- **Storage**: SharedPreferences for key-value storage
- **State Management**: Flutter's built-in StatefulWidget
- **Data Models**: JSON serialization for data persistence
- **UI Framework**: Material Design 3 with custom theming
- **Dependencies**: shared_preferences, intl for date formatting

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- Android emulator or physical device

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd token_generator
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**iOS IPA:**
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── doctor.dart          # Doctor data model
├── screens/
│   └── home_screen.dart     # Main screen with doctor list
├── services/
│   └── storage_service.dart # Local storage operations
└── widgets/
    ├── doctor_card.dart     # Individual doctor display card
    └── add_doctor_dialog.dart # Dialog for adding new doctors
```

## Data Storage

The app uses SharedPreferences to store:

- **Doctors List**: Array of doctor objects with IDs, names, specializations
- **Token Data**: Last token number and date for each doctor
- **Token History**: Recent token generation records (last 100 per doctor)

## Usage Instructions

### Adding a Doctor

1. Tap the floating action button (+)
2. Enter doctor's name and specialization
3. Tap "Add Doctor"

### Generating a Token

1. Find the doctor in the list
2. Tap "Generate Token" button
3. View the generated token number in the popup dialog

### Deleting a Doctor

1. Tap the delete icon (trash can) on the doctor's card
2. Confirm deletion in the dialog

## Features in Detail

### Daily Token Reset

- Tokens automatically reset to 1 at midnight
- No manual intervention required
- Date tracking ensures accurate daily counting

### Token History

- Each token generation is logged with timestamp
- History is limited to last 100 tokens per doctor
- Data includes token number, date, and time

### Data Validation

- Doctor names must be at least 2 characters
- Duplicate doctor names are prevented
- Form validation ensures data integrity

## Customization

### Themes

The app uses a blue color scheme that can be easily modified in `main.dart`:

```dart
theme: ThemeData(
  primarySwatch: Colors.blue,  // Change this color
  useMaterial3: true,
)
```

### Storage Limits

Token history limits can be adjusted in `storage_service.dart`:

```dart
// Keep only last 100 tokens to prevent memory issues
if (tokens.length > 100) {  // Change this number
  tokens.removeRange(0, tokens.length - 100);
}
```

## Troubleshooting

### Common Issues

1. **App won't start**: Ensure Flutter SDK is properly installed
2. **Dependencies error**: Run `flutter pub get` to install packages
3. **Build errors**: Check Flutter version compatibility

### Performance Notes

- App is optimized for local storage operations
- Token history is limited to prevent memory issues
- UI updates are efficient with proper state management

## Future Enhancements

Potential features for future versions:

- Export token data to CSV/PDF
- Multiple clinic support
- Advanced analytics and reporting
- Cloud backup options
- Patient information tracking
- Appointment scheduling integration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support or questions, please open an issue in the repository or contact the development team.

---

**Note**: This app is designed for local use in clinics and does not require internet connectivity or external services.
