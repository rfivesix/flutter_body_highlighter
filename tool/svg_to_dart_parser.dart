import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final client = HttpClient();

  final assets = {
    'male_front': {
      'url': 'https://raw.githubusercontent.com/HichamELBSI/react-native-body-highlighter/main/assets/bodyFront.ts',
      'target': 'lib/src/svg_paths/male_front_paths.dart',
      'className': 'MaleFrontPaths',
      'desc': 'Male Front',
    },
    'male_back': {
      'url': 'https://raw.githubusercontent.com/HichamELBSI/react-native-body-highlighter/main/assets/bodyBack.ts',
      'target': 'lib/src/svg_paths/male_back_paths.dart',
      'className': 'MaleBackPaths',
      'desc': 'Male Back',
    },
    'female_front': {
      'url': 'https://raw.githubusercontent.com/HichamELBSI/react-native-body-highlighter/main/assets/bodyFemaleFront.ts',
      'target': 'lib/src/svg_paths/female_front_paths.dart',
      'className': 'FemaleFrontPaths',
      'desc': 'Female Front',
    },
    'female_back': {
      'url': 'https://raw.githubusercontent.com/HichamELBSI/react-native-body-highlighter/main/assets/bodyFemaleBack.ts',
      'target': 'lib/src/svg_paths/female_back_paths.dart',
      'className': 'FemaleBackPaths',
      'desc': 'Female Back',
    },
  };

  for (final entry in assets.entries) {
    final config = entry.value;
    final url = config['url']!;
    final targetPath = config['target']!;
    final className = config['className']!;
    final desc = config['desc']!;

    print('Downloading $desc assets from $url...');
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('Failed to download $url with status code ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      print('Downloaded ${body.length} bytes for $desc. Parsing...');

      final jsonBody = cleanTsToJson(body);
      final List<dynamic> parsedList = jsonDecode(jsonBody);
      print('Successfully parsed $desc. Generating Dart file...');

      final buffer = StringBuffer();
      buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
      buffer.writeln('// Generated from $url');
      buffer.writeln();
      buffer.writeln('/// SVG path data database for $desc.');
      buffer.writeln('class $className {');
      buffer.writeln('  /// Map of body part slugs to their path direction maps.');
      buffer.writeln('  static const Map<String, Map<String, List<String>>> paths = {');

      for (final item in parsedList) {
        final slug = item['slug'] as String;
        final pathObj = item['path'] as Map<String, dynamic>;

        buffer.writeln('    \'$slug\': {');
        for (final pathEntry in pathObj.entries) {
          final side = pathEntry.key;
          final pathsList = List<String>.from(pathEntry.value as List<dynamic>);
          buffer.writeln('      \'$side\': [');
          for (final pathStr in pathsList) {
            // Escape any single quotes in the path string
            final escaped = pathStr.replaceAll("'", "\\'");
            buffer.writeln('        \'$escaped\',');
          }
          buffer.writeln('      ],');
        }
        buffer.writeln('    },');
      }

      buffer.writeln('  };');
      buffer.writeln('}');

      final file = File(targetPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(buffer.toString());
      print('Saved generated Dart file to $targetPath.');
    } catch (e) {
      stderr.writeln('Error processing $desc: $e');
      exit(1);
    }
  }

  client.close();
  print('All assets downloaded and generated successfully!');
}

String cleanTsToJson(String content) {
  // Remove comments
  content = content.replaceAll(RegExp(r'\/\/.*'), '');

  // Remove imports
  content = content.replaceAll(RegExp(r'import\s+[^;]+;'), '');

  // Remove export declarations (e.g., export const bodyFront: BodyPart[] =)
  content = content.replaceAll(RegExp(r'export\s+const\s+\w+\s*(:\s*\w+\[\])?\s*='), '');

  content = content.trim();
  if (content.endsWith(';')) {
    content = content.substring(0, content.length - 1);
  }

  // Quote unquoted keys (e.g., slug: -> "slug":)
  content = content.replaceAllMapped(RegExp(r'(\b\w+)\s*:'), (match) {
    final key = match.group(1);
    // Avoid double quoting if it was already quoted, or quoting protocol prefixes
    if (key == 'http' || key == 'https') return match.group(0)!;
    return '"$key":';
  });

  // Remove trailing commas in arrays/objects
  content = content.replaceAllMapped(RegExp(r',\s*([\}\]])'), (match) => match.group(1)!);

  // Wrap double quotes around values if single quotes are used
  // Note: in TypeScript files, they sometimes use single quotes for slug/color values.
  // We replace single quotes only if they are wrapping values, to avoid messing up single quotes inside path strings
  content = content.replaceAllMapped(RegExp(r"'\s*([^'\n]+)\s*'"), (match) {
    return '"${match.group(1)}"' ;
  });

  return content;
}
