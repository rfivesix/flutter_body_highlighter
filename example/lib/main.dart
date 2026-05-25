import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

void main() => runApp(const MyApp());

/// The main application entry point for the highlighter example.
class MyApp extends StatelessWidget {
  /// Creates the [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Body Highlighter Example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const ExamplePage(),
    );
  }
}

/// A interactive demo screen displaying the [BodyHighlighter] widget.
class ExamplePage extends StatefulWidget {
  /// Creates the [ExamplePage] widget.
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  BodyGender _gender = BodyGender.male;
  BodySide _side = BodySide.front;

  final List<BodyPartHighlightData> _highlightedParts = [
    const BodyPartHighlightData(slug: BodyPartSlug.chest, intensity: 4),
    const BodyPartHighlightData(slug: BodyPartSlug.biceps, intensity: 2),
    const BodyPartHighlightData(slug: BodyPartSlug.quadriceps, intensity: 3),
    const BodyPartHighlightData(slug: BodyPartSlug.gluteal, intensity: 5),
    const BodyPartHighlightData(slug: BodyPartSlug.lowerBack, intensity: 1),
    const BodyPartHighlightData(slug: BodyPartSlug.trapezius, intensity: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Highlighter Example'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<BodyGender>(
                    segments: const [
                      ButtonSegment(value: BodyGender.male, label: Text('Male'), icon: Icon(Icons.male)),
                      ButtonSegment(value: BodyGender.female, label: Text('Female'), icon: Icon(Icons.female)),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (set) => setState(() => _gender = set.first),
                  ),
                  const SizedBox(width: 16),
                  SegmentedButton<BodySide>(
                    segments: const [
                      ButtonSegment(value: BodySide.front, label: Text('Front')),
                      ButtonSegment(value: BodySide.back, label: Text('Back')),
                    ],
                    selected: {_side},
                    onSelectionChanged: (set) => setState(() => _side = set.first),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: BodyHighlighter(
                    gender: _gender,
                    side: _side,
                    highlightedParts: _highlightedParts,
                    width: 260,
                    height: 440,
                    outlineWidth: 1.2,
                    onBodyPartTap: (slug, highlight) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tapped: ${slug.slug.toUpperCase()} (Intensity: ${highlight.intensity ?? "none"})',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
