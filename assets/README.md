# Flutter Book Store Assets

This directory contains all the assets used in the Flutter Book Store application.

## Directory Structure

- **fonts/**: Contains font files used in the application
  - **Poppins/**: Poppins font family files
  - **Nunito/**: Nunito font family files
- **images/**: Contains image files (jpg, png, etc.) used in the application
- **icons/**: Contains icon files (svg, png) used in the application

## Usage in Flutter

These assets are registered in the `pubspec.yaml` file and can be used in the application code as follows:

### Images
```dart
Image.asset('assets/images/example.png')
```

### Icons
```dart
// For SVG icons with flutter_svg package
SvgPicture.asset('assets/icons/example.svg')

// For PNG icons
Image.asset('assets/icons/example.png')
```

### Fonts
```dart
Text(
  'Hello World',
  style: TextStyle(fontFamily: 'Poppins'),
)
``` 