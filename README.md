# Flutter Body Highlighter

A high-performance, offline-first, interactive, and zero-dependency Flutter widget for visualizing and interacting with a human body muscle model. 

Designed specifically to power rich health and fitness features—such as training volume heat maps and muscle recovery trackers—with **zero runtime XML/SVG parsing overhead** and **pixel-perfect vector fidelity**.

Based on and attributed to the coordinates from [react-native-body-highlighter](https://github.com/HichamELBSI/react-native-body-highlighter) by HichamELBSI.

---

## Features

*   **Offline-First & Zero Dependencies**: Built entirely using pure Dart and Flutter's native `CustomPainter` rendering. No external SVG parsing packages required!
*   **Dual Gender Silhouettes**: Fully supports both **Male** and **Female** body shapes.
*   **Front and Back Views**: Render either posterior or anterior chains seamlessly.
*   **Advanced Highlighting Options**:
    *   **Intensity-Based Heatmaps**: Automatically colors muscle groups on a multi-level color scale (e.g., intensities 1 to 5).
    *   **Explicit Color Overrides**: Set custom individual colors per muscle (ideal for recovery tracking, such as Orange for sore, Green for recovered, and Grey for inactive).
*   **High-DPI Responsive Scaling**: Pixel-perfect vector scaling with aspect-ratio preservation.
*   **Pure-Dart Tap Collision Detection**: Extremely fast, mathematical tap detection maps user clicks directly back to specific muscle group slugs.

---

## Installation

Add the package as a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_body_highlighter:
    git:
      url: https://github.com/rfivesix/flutter_body_highlighter.git
      ref: main
```

---

## Quick Start Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const BodyHighlighterDemo(),
    );
  }
}

class BodyHighlighterDemo extends StatefulWidget {
  const BodyHighlighterDemo({super.key});

  @override
  State<BodyHighlighterDemo> createState() => _BodyHighlighterDemoState();
}

class _BodyHighlighterDemoState extends State<BodyHighlighterDemo> {
  BodyGender _gender = BodyGender.male;
  BodySide _side = BodySide.front;
  BodyPartSlug? _selectedMuscle;

  // Track highlights
  final List<BodyPartHighlightData> _highlights = [
    const BodyPartHighlightData(slug: BodyPartSlug.chest, intensity: 5),
    const BodyPartHighlightData(slug: BodyPartSlug.quadriceps, intensity: 3),
    const BodyPartHighlightData(slug: BodyPartSlug.biceps, intensity: 2),
    const BodyPartHighlightData(slug: BodyPartSlug.gluteal, color: Colors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Highlighter Demo'),
        actions: [
          IconButton(
            icon: Icon(_gender == BodyGender.male ? Icons.male : Icons.female),
            onPressed: () => setState(() {
              _gender = _gender == BodyGender.male ? BodyGender.female : BodyGender.male;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.flip),
            onPressed: () => setState(() {
              _side = _side == BodySide.front ? BodySide.back : BodySide.front;
            }),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _selectedMuscle != null
                    ? 'Tapped: ${_selectedMuscle!.slug.toUpperCase()}'
                    : 'Tap on a muscle group!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: BodyHighlighter(
                  gender: _gender,
                  side: _side,
                  highlightedParts: _highlights,
                  outlineWidth: 1.2,
                  onBodyPartTap: (slug, highlight) {
                    setState(() {
                      _selectedMuscle = slug;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## API Reference

### 1. `BodyHighlighter` (Widget)

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `highlightedParts` | `List<BodyPartHighlightData>` | **Required** | The collection of muscles and their highlighting parameters. |
| `gender` | `BodyGender` | `BodyGender.male` | Silhouette gender (`male` or `female`). |
| `side` | `BodySide` | `BodySide.front` | Side of the body displayed (`front` or `back`). |
| `baseColor` | `Color?` | `surfaceContainerHighest` | Base fill color for all unhighlighted body parts. |
| `outlineColor` | `Color?` | `outline` | Border outline color of all body parts. |
| `outlineWidth` | `double` | `1.0` | Stroke width for outlines. |
| `intensityColors` | `List<Color>?` | *Gradient theme-primary* | 5-step color scale used to shade muscles based on `intensity`. |
| `onBodyPartTap` | `Function(BodyPartSlug, BodyPartHighlightData)?` | `null` | Tap callback. If `null`, tap detection is disabled. |
| `width` | `double?` | `null` | Optional width constraint. |
| `height` | `double?` | `null` | Optional height constraint. |

### 2. `BodyPartHighlightData` (Model)

An input data model configuring how a specific muscle group is highlighted:

```dart
const BodyPartHighlightData({
  required this.slug,     // The target muscle group BodyPartSlug
  this.intensity,         // Shading level [1-5] corresponding to the intensity colors
  this.color,             // Direct color override (ignores intensity if supplied)
  this.payload,           // Custom payload to carry domain-specific objects
});
```

### 3. `BodyPartSlug` (Enum)

Strong-typed enum representation of all interactive muscle groups. Includes a `fromString(String slug)` helper to convert database strings automatically:

```dart
enum BodyPartSlug {
  neck,
  trapezius,
  upperBack,
  lowerBack,
  chest,
  abs,
  obliques,
  frontDeltoids,
  backDeltoids,
  biceps,
  triceps,
  forearm,
  gluteal,
  quadriceps,
  hamstring,
  adductor,
  abductors,
  calves;
  
  static BodyPartSlug? fromString(String slug);
  String get slug;
}
```

---

## Development & Regeneration of Assets

If you ever need to download the latest TS files and rebuild the compiled Dart coordinate databases, run the build-time downloader script:

```bash
dart tool/svg_to_dart_parser.dart
```

This will automatically connect to GitHub, download the TS vectors, optimize coordinates, remove trailing commas, and write clean Dart structures under `lib/src/svg_paths/`.

---

## License

This package is distributed under the [MIT License](file:///Users/richardgeorgschotte/Projekte/flutter_body_highlighter/LICENSE). It attributes and preserves copyright to both Richard Georg Schotte and HichamELBSI.
