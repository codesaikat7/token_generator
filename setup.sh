#!/bin/bash

echo "🚀 Setting up QueueMed Flutter App"
echo "================================================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter is installed: $(flutter --version | head -n 1)"

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | grep -o "Flutter [0-9]\+\.[0-9]\+\.[0-9]\+" | cut -d' ' -f2)
echo "📱 Flutter version: $FLUTTER_VERSION"

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Check for any issues
echo "🔍 Checking for any issues..."
flutter doctor

echo ""
echo "🎉 Setup complete! You can now run the app with:"
echo "   flutter run"
echo ""
echo "📱 To build for production:"
echo "   Android: flutter build apk --release"
echo "   iOS: flutter build ios --release"
echo ""
echo "📚 For more information, see README.md"
