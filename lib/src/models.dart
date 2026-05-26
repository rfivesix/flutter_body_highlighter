import 'package:flutter/material.dart';

/// Represents the gender silhouette of the body.
enum BodyGender {
  /// Male body silhouette.
  male,

  /// Female body silhouette.
  female,
}

/// Represents the side of the body being displayed.
enum BodySide {
  /// Front view of the body.
  front,

  /// Back view of the body.
  back,
}

/// Strongly-typed slugs representing each supported muscle/body part.
enum BodyPartSlug {
  /// The neck area.
  neck,

  /// Trapezius muscles (upper back and neck area).
  trapezius,

  /// Upper back muscles (rhomboids, mid-traps).
  upperBack,

  /// Lower back muscles (spinal erectors).
  lowerBack,

  /// Chest muscles (pectorals).
  chest,

  /// Abdominal muscles (rectus abdominis).
  abs,

  /// Oblique muscles (side abdominals).
  obliques,

  /// Front deltoids (anterior shoulder).
  frontDeltoids,

  /// Back deltoids (posterior shoulder).
  backDeltoids,

  /// Biceps brachii.
  biceps,

  /// Triceps brachii.
  triceps,

  /// Forearm muscles.
  forearm,

  /// Gluteal muscles (gluteus maximus, medius, minimus).
  gluteal,

  /// Quadriceps (front thigh).
  quadriceps,

  /// Hamstrings (back thigh).
  hamstring,

  /// Adductors (inner thigh).
  adductor,

  /// Abductors (outer hip/thigh).
  abductors,

  /// Calves (gastrocnemius and soleus).
  calves,

  /// Tibialis anterior (front lower leg).
  tibialis;

  /// Utility to convert string slug from DB/JSON to Enum value.
  static BodyPartSlug? fromString(String slug) {
    switch (slug.toLowerCase().trim().replaceAll('_', '-')) {
      case 'neck':
        return BodyPartSlug.neck;
      case 'trapezius':
      case 'traps':
        return BodyPartSlug.trapezius;
      case 'upper-back':
      case 'upperback':
        return BodyPartSlug.upperBack;
      case 'lower-back':
      case 'lowerback':
        return BodyPartSlug.lowerBack;
      case 'chest':
      case 'pecs':
        return BodyPartSlug.chest;
      case 'abs':
        return BodyPartSlug.abs;
      case 'obliques':
        return BodyPartSlug.obliques;
      case 'front-deltoids':
      case 'front-delts':
      case 'front-delt':
      case 'deltoids':
      case 'shoulders':
      case 'shoulder':
      case 'anterior-deltoids':
        return BodyPartSlug.frontDeltoids;
      case 'back-deltoids':
      case 'back-delts':
      case 'back-delt':
      case 'rear-deltoids':
      case 'rear-delts':
      case 'rear-delt':
      case 'posterior-deltoids':
        return BodyPartSlug.backDeltoids;
      case 'biceps':
        return BodyPartSlug.biceps;
      case 'triceps':
        return BodyPartSlug.triceps;
      case 'forearm':
      case 'forearms':
        return BodyPartSlug.forearm;
      case 'gluteal':
      case 'glutes':
        return BodyPartSlug.gluteal;
      case 'quadriceps':
      case 'quads':
        return BodyPartSlug.quadriceps;
      case 'hamstring':
      case 'hamstrings':
        return BodyPartSlug.hamstring;
      case 'adductor':
      case 'adductors':
        return BodyPartSlug.adductor;
      case 'abductors':
        return BodyPartSlug.abductors;
      case 'calves':
      case 'calf':
        return BodyPartSlug.calves;
      case 'tibialis':
        return BodyPartSlug.tibialis;
      default:
        return null;
    }
  }

  /// Converts this enum value back to its standard string slug.
  String get slug {
    switch (this) {
      case BodyPartSlug.neck:
        return 'neck';
      case BodyPartSlug.trapezius:
        return 'trapezius';
      case BodyPartSlug.upperBack:
        return 'upper-back';
      case BodyPartSlug.lowerBack:
        return 'lower-back';
      case BodyPartSlug.chest:
        return 'chest';
      case BodyPartSlug.abs:
        return 'abs';
      case BodyPartSlug.obliques:
        return 'obliques';
      case BodyPartSlug.frontDeltoids:
        return 'front-deltoids';
      case BodyPartSlug.backDeltoids:
        return 'back-deltoids';
      case BodyPartSlug.biceps:
        return 'biceps';
      case BodyPartSlug.triceps:
        return 'triceps';
      case BodyPartSlug.forearm:
        return 'forearm';
      case BodyPartSlug.gluteal:
        return 'gluteal';
      case BodyPartSlug.quadriceps:
        return 'quadriceps';
      case BodyPartSlug.hamstring:
        return 'hamstring';
      case BodyPartSlug.adductor:
        return 'adductor';
      case BodyPartSlug.abductors:
        return 'abductors';
      case BodyPartSlug.calves:
        return 'calves';
      case BodyPartSlug.tibialis:
        return 'tibialis';
    }
  }
}

/// Input configuration for highlighting a specific body part.
class BodyPartHighlightData {
  /// The body part slug identifying which muscle group is highlighted.
  final BodyPartSlug slug;

  /// Color intensity level, e.g., from 1 to 5.
  /// If set, the color is selected from the widget's [intensityColors] palette.
  final int? intensity;

  /// Explicit color override. If provided, ignores [intensity] and uses this color.
  /// Perfect for showing recovery states (e.g., Orange for recovering, Green for fresh).
  final Color? color;

  /// Custom payload to carry domain-specific objects (e.g., recovery metrics).
  final Object? payload;

  /// Creates a configuration for highlighting a specific body part.
  const BodyPartHighlightData({
    required this.slug,
    this.intensity,
    this.color,
    this.payload,
  });
}
