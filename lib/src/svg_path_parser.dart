import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// A scanner to parse SVG path data strings character-by-character on the fly,
/// correctly resolving SVG coordinate syntax, separator rules, and flag parsing.
class SvgPathScanner {
  /// The raw SVG path data text.
  final String text;

  /// The current index of the scanner.
  int index = 0;

  /// Creates a scanner for the given SVG path string.
  SvgPathScanner(this.text);

  /// Whether the scanner has reached the end of the text.
  bool get isDone => index >= text.length;

  /// Skips all whitespaces and commas.
  void skipWhitespace() {
    while (index < text.length) {
      final code = text.codeUnitAt(index);
      if (code == 32 || code == 9 || code == 10 || code == 13 || code == 44) {
        index++;
      } else {
        break;
      }
    }
  }

  /// Tries to read a command character (A-Z or a-z) at the current position.
  String? readCommand() {
    skipWhitespace();
    if (isDone) return null;
    final char = text[index];
    if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
      index++;
      return char;
    }
    return null;
  }

  /// Verifies if a character is a command.
  bool isCommand() {
    skipWhitespace();
    if (isDone) return false;
    final char = text[index];
    return RegExp(r'[a-zA-Z]').hasMatch(char);
  }

  /// Reads a floating-point number at the current position.
  double readNumber() {
    skipWhitespace();
    if (isDone) return 0.0;

    final start = index;
    // Handle optional leading sign
    if (text[index] == '-' || text[index] == '+') {
      index++;
    }

    // Read integer digits
    while (index < text.length && _isDigit(text.codeUnitAt(index))) {
      index++;
    }

    // Read decimal point and fractional digits
    if (index < text.length && text[index] == '.') {
      index++;
      while (index < text.length && _isDigit(text.codeUnitAt(index))) {
        index++;
      }
    }

    // Read scientific exponent
    if (index < text.length && (text[index] == 'e' || text[index] == 'E')) {
      // Check if exponent is actually followed by a number
      if (index + 1 < text.length) {
        final nextChar = text[index + 1];
        if (_isDigit(nextChar.codeUnitAt(0)) || nextChar == '-' || nextChar == '+') {
          index++;
          if (text[index] == '-' || text[index] == '+') {
            index++;
          }
          while (index < text.length && _isDigit(text.codeUnitAt(index))) {
            index++;
          }
        }
      }
    }

    if (index == start) {
      throw FormatException('Expected number at position $start in path: $text');
    }

    final numberStr = text.substring(start, index);
    final val = double.tryParse(numberStr);
    if (val == null) {
      throw FormatException('Invalid number format: $numberStr in path: $text');
    }
    return val;
  }

  /// Reads a single-digit flag (0 or 1) for the SVG arcTo command.
  double readFlag() {
    skipWhitespace();
    if (isDone) {
      throw FormatException('Expected flag (0 or 1) but reached end of string in path: $text');
    }
    final char = text[index];
    if (char == '0' || char == '1') {
      index++;
      return char == '1' ? 1.0 : 0.0;
    }
    throw FormatException('Expected flag (0 or 1) at position $index, got: $char in path: $text');
  }

  bool _isDigit(int code) {
    return code >= 48 && code <= 57;
  }
}

/// A high-performance, pure-Dart parser for SVG path data strings.
///
/// Parses standard SVG path strings and draws them directly into a Flutter [Path] object.
class SvgPathParser {
  /// Parses the SVG path data string [pathData] and returns a Flutter [Path].
  static Path parse(String pathData) {
    final path = Path();
    final scanner = SvgPathScanner(pathData);

    double cursorX = 0.0;
    double cursorY = 0.0;
    double lastControlX = 0.0;
    double lastControlY = 0.0;
    String lastCommand = '';

    while (!scanner.isDone) {
      scanner.skipWhitespace();
      if (scanner.isDone) break;

      // Determine command
      String command;
      if (scanner.isCommand()) {
        command = scanner.readCommand()!;
      } else {
        // Implicit repeat of previous command
        if (lastCommand.isEmpty) {
          throw FormatException('Unexpected numeric token without previous command in path: $pathData');
        }
        // Implicit repeat rules
        if (lastCommand == 'M') {
          command = 'L';
        } else if (lastCommand == 'm') {
          command = 'l';
        } else {
          command = lastCommand;
        }
      }

      lastCommand = command;

      switch (command) {
        case 'M':
          final x = scanner.readNumber();
          final y = scanner.readNumber();
          path.moveTo(x, y);
          cursorX = x;
          cursorY = y;
          break;

        case 'm':
          final dx = scanner.readNumber();
          final dy = scanner.readNumber();
          cursorX += dx;
          cursorY += dy;
          path.moveTo(cursorX, cursorY);
          break;

        case 'L':
          final x = scanner.readNumber();
          final y = scanner.readNumber();
          path.lineTo(x, y);
          cursorX = x;
          cursorY = y;
          break;

        case 'l':
          final dx = scanner.readNumber();
          final dy = scanner.readNumber();
          cursorX += dx;
          cursorY += dy;
          path.lineTo(cursorX, cursorY);
          break;

        case 'H':
          final x = scanner.readNumber();
          path.lineTo(x, cursorY);
          cursorX = x;
          break;

        case 'h':
          final dx = scanner.readNumber();
          cursorX += dx;
          path.lineTo(cursorX, cursorY);
          break;

        case 'V':
          final y = scanner.readNumber();
          path.lineTo(cursorX, y);
          cursorY = y;
          break;

        case 'v':
          final dy = scanner.readNumber();
          cursorY += dy;
          path.lineTo(cursorX, cursorY);
          break;

        case 'C':
          final x1 = scanner.readNumber();
          final y1 = scanner.readNumber();
          final x2 = scanner.readNumber();
          final y2 = scanner.readNumber();
          final x = scanner.readNumber();
          final y = scanner.readNumber();
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          cursorX = x;
          cursorY = y;
          break;

        case 'c':
          final dx1 = scanner.readNumber();
          final dy1 = scanner.readNumber();
          final dx2 = scanner.readNumber();
          final dy2 = scanner.readNumber();
          final dx = scanner.readNumber();
          final dy = scanner.readNumber();
          path.cubicTo(cursorX + dx1, cursorY + dy1, cursorX + dx2, cursorY + dy2, cursorX + dx, cursorY + dy);
          lastControlX = cursorX + dx2;
          lastControlY = cursorY + dy2;
          cursorX += dx;
          cursorY += dy;
          break;

        case 'S':
          final x2 = scanner.readNumber();
          final y2 = scanner.readNumber();
          final x = scanner.readNumber();
          final y = scanner.readNumber();
          double x1 = cursorX;
          double y1 = cursorY;
          if (lastCommand == 'C' || lastCommand == 'c' || lastCommand == 'S' || lastCommand == 's') {
            x1 = 2 * cursorX - lastControlX;
            y1 = 2 * cursorY - lastControlY;
          }
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          cursorX = x;
          cursorY = y;
          break;

        case 's':
          final dx2 = scanner.readNumber();
          final dy2 = scanner.readNumber();
          final dx = scanner.readNumber();
          final dy = scanner.readNumber();
          double x1 = cursorX;
          double y1 = cursorY;
          if (lastCommand == 'C' || lastCommand == 'c' || lastCommand == 'S' || lastCommand == 's') {
            x1 = 2 * cursorX - lastControlX;
            y1 = 2 * cursorY - lastControlY;
          }
          final x2 = cursorX + dx2;
          final y2 = cursorY + dy2;
          final x = cursorX + dx;
          final y = cursorY + dy;
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          cursorX = x;
          cursorY = y;
          break;

        case 'Q':
          final x1 = scanner.readNumber();
          final y1 = scanner.readNumber();
          final x = scanner.readNumber();
          final y = scanner.readNumber();
          path.quadraticBezierTo(x1, y1, x, y);
          lastControlX = x1;
          lastControlY = y1;
          cursorX = x;
          cursorY = y;
          break;

        case 'q':
          final dx1 = scanner.readNumber();
          final dy1 = scanner.readNumber();
          final dx = scanner.readNumber();
          final dy = scanner.readNumber();
          path.quadraticBezierTo(cursorX + dx1, cursorY + dy1, cursorX + dx, cursorY + dy);
          lastControlX = cursorX + dx1;
          lastControlY = cursorY + dy1;
          cursorX += dx;
          cursorY += dy;
          break;

        case 'A':
        case 'a':
          final rx = scanner.readNumber();
          final ry = scanner.readNumber();
          final xAxisRotation = scanner.readNumber();
          final largeArcFlag = scanner.readFlag() != 0.0;
          final sweepFlag = scanner.readFlag() != 0.0;
          final x = command == 'a' ? cursorX + scanner.readNumber() : scanner.readNumber();
          final y = command == 'a' ? cursorY + scanner.readNumber() : scanner.readNumber();

          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: xAxisRotation * math.pi / 180.0,
            largeArc: largeArcFlag,
            clockwise: sweepFlag,
          );

          cursorX = x;
          cursorY = y;
          break;

        case 'Z':
        case 'z':
          path.close();
          break;

        default:
          throw FormatException('Unsupported SVG command: $command in path: $pathData');
      }
    }

    return path;
  }
}
