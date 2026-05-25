# Contributing to flutter_body_highlighter

Thank you for your interest in contributing to `flutter_body_highlighter`!

## Code of Conduct

Please treat everyone with respect and follow standard community guidelines.

## How to Contribute

1. Fork the repository and create your branch from `main`.
2. Ensure you run the SVG parser script if you are modifying raw TS/SVG coordinate assets:
   ```bash
   dart tool/svg_to_dart_parser.dart
   ```
3. Make sure all code compiles and conforms to style guidelines by running:
   ```bash
   flutter analyze
   ```
4. Run tests before submitting a Pull Request:
   ```bash
   flutter test
   ```
5. Commit your changes and open a Pull Request explaining the enhancements.
