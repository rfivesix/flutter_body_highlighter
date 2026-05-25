import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'svg_path_parser.dart';
import 'svg_paths/female_back_paths.dart';
import 'svg_paths/female_front_paths.dart';
import 'svg_paths/male_back_paths.dart';
import 'svg_paths/male_front_paths.dart';

/// A static cache to store parsed Flutter [Path] objects lazily,
/// avoiding the CPU overhead of parsing SVG coordinate strings on every frame.
class BodyPathCache {
  static final Map<String, Path> _cache = {};

  /// Retrieves or parses a Flutter [Path] object from the cache.
  static Path getPath({
    required BodyGender gender,
    required BodySide side,
    required String slug,
    required String direction,
    required int index,
    required String pathData,
  }) {
    final cacheKey = '${gender.name}_${side.name}_${slug}_${direction}_$index';
    return _cache.putIfAbsent(cacheKey, () => SvgPathParser.parse(pathData));
  }
}

/// CustomPainter for drawing the human body silhouette and muscle highlights.
class BodyPainter extends CustomPainter {
  /// The collection of highlighted muscles and their configurations.
  final List<BodyPartHighlightData> highlightedParts;

  /// Gender silhouette of the body.
  final BodyGender gender;

  /// Side of the body displayed.
  final BodySide side;

  /// Base color for unhighlighted body parts.
  final Color baseColor;

  /// Outline border color for all body parts.
  final Color outlineColor;

  /// Stroke width for outlines.
  final double outlineWidth;

  /// Color palette used to shade muscles based on their intensity values.
  final List<Color> intensityColors;

  /// Creates a [BodyPainter] to render the body silhouette.
  const BodyPainter({
    required this.highlightedParts,
    required this.gender,
    required this.side,
    required this.baseColor,
    required this.outlineColor,
    required this.outlineWidth,
    required this.intensityColors,
  });

  /// Standard viewBox rectangles for each configuration.
  static const Map<String, Rect> viewBoxes = {
    'male_front': Rect.fromLTWH(0, 0, 724, 1448),
    'male_back': Rect.fromLTWH(724, 0, 724, 1448),
    'female_front': Rect.fromLTWH(-50, -40, 734, 1538),
    'female_back': Rect.fromLTWH(756, 0, 774, 1448),
  };

  /// Returns the viewBox rectangle for the current gender and side configuration.
  Rect get viewBox {
    final key = '${gender.name}_${side.name}';
    return viewBoxes[key] ?? const Rect.fromLTWH(0, 0, 724, 1448);
  }

  /// Gets the path database map for the current configuration.
  Map<String, Map<String, List<String>>> get _pathDatabase {
    if (gender == BodyGender.male) {
      return side == BodySide.front ? MaleFrontPaths.paths : MaleBackPaths.paths;
    } else {
      return side == BodySide.front ? FemaleFrontPaths.paths : FemaleBackPaths.paths;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final box = viewBox;
    final scaleX = size.width / box.width;
    final scaleY = size.height / box.height;
    final scale = math.min(scaleX, scaleY);

    final dx = (size.width - box.width * scale) / 2;
    final dy = (size.height - box.height * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);
    canvas.translate(-box.left, -box.top);

    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = outlineColor
      ..strokeWidth = outlineWidth / scale // Scale outline width back so it renders uniformly at outlineWidth
      ..isAntiAlias = true;

    final database = _pathDatabase;

    // Render each body part in the order defined in database (natural stack order)
    for (final entry in database.entries) {
      final partSlugStr = entry.key;
      final directionMap = entry.value;

      // Find if this body part is highlighted
      final mappedSlug = BodyPartSlug.fromString(partSlugStr);
      BodyPartHighlightData? highlight;
      if (mappedSlug != null) {
        for (final data in highlightedParts) {
          if (data.slug == mappedSlug) {
            highlight = data;
            break;
          }
        }
      }

      // Determine fill color
      Color fillColor = baseColor;
      if (highlight != null) {
        if (highlight.color != null) {
          fillColor = highlight.color!;
        } else if (highlight.intensity != null && intensityColors.isNotEmpty) {
          final idx = (highlight.intensity!.clamp(1, intensityColors.length)) - 1;
          fillColor = intensityColors[idx];
        }
      }

      paintFill.color = fillColor;

      // Draw all direction paths for this body part
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

          canvas.drawPath(path, paintFill);
          canvas.drawPath(path, paintStroke);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BodyPainter oldDelegate) {
    return oldDelegate.gender != gender ||
        oldDelegate.side != side ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.outlineWidth != outlineWidth ||
        oldDelegate.highlightedParts != highlightedParts ||
        oldDelegate.intensityColors != intensityColors;
  }
}
