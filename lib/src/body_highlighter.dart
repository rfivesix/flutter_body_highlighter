import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'body_painter.dart';
import 'models.dart';
import 'svg_paths/female_back_paths.dart';
import 'svg_paths/female_front_paths.dart';
import 'svg_paths/male_back_paths.dart';
import 'svg_paths/male_front_paths.dart';

/// A high-performance, interactive, zero-dependency human body muscle highlighter widget.
///
/// Supports separate front/back views, male/female silhouettes, and tap target detection
/// on individual muscle groups with robust aspect-ratio scaling.
class BodyHighlighter extends StatelessWidget {
  /// The collection of muscles and their highlighting parameters.
  final List<BodyPartHighlightData> highlightedParts;

  /// Silhouette gender. Defaults to [BodyGender.male].
  final BodyGender gender;

  /// Which side to display. Defaults to [BodySide.front].
  final BodySide side;

  /// Base fill color for all unhighlighted body parts.
  /// Defaults to [ThemeData.colorScheme.surfaceContainerHighest] or [Colors.grey.shade300].
  final Color? baseColor;

  /// Border color of body outlines and muscle boundaries.
  /// Defaults to [ThemeData.colorScheme.outline] or [Colors.grey].
  final Color? outlineColor;

  /// Stroke width for the borders. Defaults to 1.0.
  final double outlineWidth;

  /// Color palette used to shade muscles based on their intensity values (from 1 to 5).
  /// If null, a premium gradient matching the current Theme's primary color is used.
  final List<Color>? intensityColors;

  /// Callback when a muscle/body part is tapped.
  /// If null, tap detection is disabled.
  final void Function(BodyPartSlug slug, BodyPartHighlightData highlight)? onBodyPartTap;

  /// Optional width constraint. If null, expands to fill constraints.
  final double? width;

  /// Optional height constraint. If null, expands to fill constraints.
  final double? height;

  /// Creates an interactive [BodyHighlighter] widget.
  const BodyHighlighter({
    super.key,
    required this.highlightedParts,
    this.gender = BodyGender.male,
    this.side = BodySide.front,
    this.baseColor,
    this.outlineColor,
    this.outlineWidth = 1.0,
    this.intensityColors,
    this.onBodyPartTap,
    this.width,
    this.height,
  });

  /// Standard viewBox rectangles for each configuration.
  Rect get _viewBox {
    final key = '${gender.name}_${side.name}';
    return BodyPainter.viewBoxes[key] ?? const Rect.fromLTWH(0, 0, 724, 1448);
  }

  /// Gets the path database map for the current configuration.
  Map<String, Map<String, List<String>>> get _pathDatabase {
    if (gender == BodyGender.male) {
      return side == BodySide.front ? MaleFrontPaths.paths : MaleBackPaths.paths;
    } else {
      return side == BodySide.front ? FemaleFrontPaths.paths : FemaleBackPaths.paths;
    }
  }

  List<Color> _getEffectiveIntensityColors(BuildContext context) {
    if (intensityColors != null) return intensityColors!;

    final primary = Theme.of(context).colorScheme.primary;
    return [
      // ignore: deprecated_member_use
      primary.withOpacity(0.15),
      // ignore: deprecated_member_use
      primary.withOpacity(0.35),
      // ignore: deprecated_member_use
      primary.withOpacity(0.55),
      // ignore: deprecated_member_use
      primary.withOpacity(0.75),
      primary,
    ];
  }

  void _handleTap(TapUpDetails details, Size size) {
    if (onBodyPartTap == null) return;

    final box = _viewBox;
    final scaleX = size.width / box.width;
    final scaleY = size.height / box.height;
    final scale = math.min(scaleX, scaleY);

    final dx = (size.width - box.width * scale) / 2;
    final dy = (size.height - box.height * scale) / 2;

    final localPosition = details.localPosition;

    // Inverse transform from local widget coordinate system back to SVG viewBox space:
    // svgOffset = (localPosition - alignmentOffset) / scale + viewBoxOffset
    final svgX = (localPosition.dx - dx) / scale + box.left;
    final svgY = (localPosition.dy - dy) / scale + box.top;
    final svgOffset = Offset(svgX, svgY);

    final database = _pathDatabase;

    // Check hit collision on all parts in stack order
    for (final entry in database.entries) {
      final partSlugStr = entry.key;
      final mappedSlug = BodyPartSlug.fromString(partSlugStr);
      if (mappedSlug == null) continue; // Skip head, hair, or unrecognized paths in tap detection

      final directionMap = entry.value;
      bool isHit = false;

      for (final pathEntry in directionMap.entries) {
        final direction = pathEntry.key;
        final pathList = pathEntry.value;

        for (int i = 0; i < pathList.length; i++) {
          final pathStr = pathList[i];
          final path = BodyPathCache.getPath(
            gender: gender,
            side: side,
            slug: partSlugStr,
            direction: direction,
            index: i,
            pathData: pathStr,
          );

          if (path.contains(svgOffset)) {
            isHit = true;
            break;
          }
        }
        if (isHit) break;
      }

      if (isHit) {
        // Find existing highlight data or create default
        final highlight = highlightedParts.firstWhere(
          (h) => h.slug == mappedSlug,
          orElse: () => BodyPartHighlightData(slug: mappedSlug),
        );
        onBodyPartTap!(mappedSlug, highlight);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBaseColor = baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveOutlineColor = outlineColor ?? theme.colorScheme.outline;
    final effectiveIntensityColors = _getEffectiveIntensityColors(context);

    Widget buildBody(BoxConstraints constraints) {
      final size = Size(
        width ?? constraints.maxWidth,
        height ?? constraints.maxHeight,
      );

      return GestureDetector(
        onTapUp: onBodyPartTap != null ? (details) => _handleTap(details, size) : null,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          size: size,
          painter: BodyPainter(
            highlightedParts: highlightedParts,
            gender: gender,
            side: side,
            baseColor: effectiveBaseColor,
            outlineColor: effectiveOutlineColor,
            outlineWidth: outlineWidth,
            intensityColors: effectiveIntensityColors,
          ),
        ),
      );
    }

    if (width != null && height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: LayoutBuilder(builder: (context, constraints) => buildBody(constraints)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => buildBody(constraints),
    );
  }
}
