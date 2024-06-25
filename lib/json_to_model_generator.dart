library json_to_model_generator;
import 'dart:convert';

class JsonToModelGenerator {
  String generateModel(String className, String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    final StringBuffer classBuffer = StringBuffer();
    classBuffer.writeln('class $className {');

    jsonMap.forEach((key, value) {
      final String fieldType = _getFieldType(key, value);
      classBuffer.writeln('  final $fieldType? $key;');
    });

    // Constructor
    classBuffer.writeln();
    classBuffer.writeln('  $className({');
    jsonMap.forEach((key, _) {
      classBuffer.writeln('    this.$key,');
    });
    classBuffer.writeln('  });');

    // fromJson factory
    classBuffer.writeln();
    classBuffer
        .writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    classBuffer.writeln('    return $className(');
    jsonMap.forEach((key, value) {
      final String constructorParam = _getConstructorParam(key, value);
      classBuffer.writeln('      $key: $constructorParam,');
    });
    classBuffer.writeln('    );');
    classBuffer.writeln('  }');

    // toJson method
    classBuffer.writeln();
    classBuffer.writeln('  Map<String, dynamic> toJson() {');
    classBuffer.writeln('    return {');
    jsonMap.forEach((key, _) {
      classBuffer.writeln('      \'$key\': $key,');
    });
    classBuffer.writeln('    };');
    classBuffer.writeln('  }');

    classBuffer.writeln('}');

    // Generate nested classes
    jsonMap.forEach((key, value) {
      if (value is Map) {
        final String nestedClassName = _capitalize(key);
        classBuffer.writeln(generateModel(nestedClassName, jsonEncode(value)));
      }
    });

    return classBuffer.toString();
  }

  String _getFieldType(String key, dynamic value) {
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is String) return 'String';
    if (value is List) {
      if (value.isNotEmpty) {
        return 'List<${_getFieldType(key, value.first)}>';
      }
      return 'List<dynamic>';
    }
    if (value is Map) return _capitalize(key);
    return 'dynamic';
  }

  String _getConstructorParam(String key, dynamic value) {
    if (value is Map) {
      return 'json[\'$key\'] != null ? ${_capitalize(key)}.fromJson(json[\'$key\']) : null';
    }
    if (value is List) {
      if (value.isNotEmpty && value.first is Map) {
        return 'json[\'$key\'] != null ? (json[\'$key\'] as List).map((e) => ${_capitalize(key)}.fromJson(e)).toList() : null';
      }
      if (value.isNotEmpty) {
        return 'json[\'$key\'] != null ? List<${_getFieldType(key, value.first)}>.from(json[\'$key\']) : null';
      } else {
        return 'null'; // Handle empty list case
      }
    }
    return 'json[\'$key\'] ?? null'; // Handle any other type with a fallback
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}