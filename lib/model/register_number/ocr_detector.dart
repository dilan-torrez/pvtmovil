// text_detector.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:muserpol_pvt/utils/logger.dart'; // SEGURIDAD: Import para logging seguro
import 'files_state_veritify.dart';
import 'file_document.dart';

class TextDetector {
  static Future<TextDetectionResult> detectText({
    required InputImage inputImage,
    required File fileImage,
    required FileDocument item,
    required FilesStateVeritify filesState,
    required String userInput,
  }) async {
    try {
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      // Validar que sea un documento
      final documentValidation = _validateDocument(recognizedText.text);

      if (!documentValidation.isValid) {
        return TextDetectionResult(
          success: false,
          match: false,
          detectedText: recognizedText.text,
          error: documentValidation.errorMessage,
          isDocumentValid: false,
          validationScore: documentValidation.score,
          matchedBlocks: [],
        );
      }

      // debugPrint("===== TEXTO DETECTADO =====");
      // debugPrint(recognizedText.text);
      // debugPrint("===========================");

      final matches = _findTextMatches(recognizedText, userInput);
      // Actualizar el estado
      filesState.updateFile(item.id, fileImage);
      filesState.updateMatchedBlocks(item.id, matches);

      final hasMatch = matches.isNotEmpty;
      filesState.updateStateFiles(item.id, hasMatch);

      // Verificar coincidencia (case insensitive)
      final cleanedDetectedText = recognizedText.text.toLowerCase().trim();
      final cleanedUserInput = userInput.toLowerCase().trim();

      final rawContains = cleanedDetectedText.contains(cleanedUserInput);

      // Comparación difusa del número de cédula tolerando errores típicos de OCR
      final userDigits = userInput.replaceAll(RegExp(r'[^0-9]'), '');
      final digitMatch = userDigits.length >= 4
          ? _fuzzyCiMatch(_extractDigitCandidates(recognizedText), userDigits)
          : false;

      final match = rawContains || digitMatch;

      filesState.updateStateFiles(item.id, match);

      return TextDetectionResult(
        success: true,
        match: match,
        detectedText: recognizedText.text,
        error: null,
        isDocumentValid: true,
        validationScore: documentValidation.score,
        matchedBlocks: matches,
      );
    } catch (e) {
      // SEGURIDAD: Uso de AppLog para evitar registros en producción
      AppLog.d("Error en detección de texto: $e");
      return TextDetectionResult(
        success: false,
        match: false,
        detectedText: '',
        error: e.toString(),
        isDocumentValid: false,
        validationScore: 0,
        matchedBlocks: [],
      );
    }
  }

  static List<TextBlock> _findTextMatches(
    RecognizedText recognizedText,
    String userInput,
  ) {
    final searchText = userInput.toLowerCase().trim();
    final matches = <TextBlock>[];

    for (final block in recognizedText.blocks) {
      final blockText = block.text.toLowerCase();
      if (blockText.contains(searchText)) {
        matches.add(block);
      } else {
        // Buscar también en las líneas individuales
        for (final line in block.lines) {
          if (line.text.toLowerCase().contains(searchText)) {
            matches.add(block);
            break;
          }
        }
      }
    }

    return matches;
  }

  static List<String> _extractDigitCandidates(RecognizedText recognizedText) {
    final candidates = <String>{};

    void add(String s) {
      final d = s.replaceAll(RegExp(r'[^0-9]'), '');
      if (d.length >= 4) candidates.add(d);
    }

    add(recognizedText.text);
    for (final block in recognizedText.blocks) {
      add(block.text);
      for (final run in RegExp(r'\d{4,}').allMatches(block.text)) {
        add(run.group(0)!);
      }
      for (final line in block.lines) {
        add(line.text);
        for (final run in RegExp(r'\d{4,}').allMatches(line.text)) {
          add(run.group(0)!);
        }
      }
    }
    return candidates.toList();
  }

  static bool _fuzzyCiMatch(List<String> candidates, String userDigits) {
    // Cédulas con sufijo alfanumérico (ej. "4924581 LP", nacionalizados)
    // se comparan solo por dígitos; las letras del sufijo no interfiere.
    final maxErrors = userDigits.length >= 10
        ? 2
        : (userDigits.length >= 5 ? 1 : 0);
    for (final candidate in candidates) {
      if (candidate == userDigits) return true;
      for (final window in [userDigits.length, userDigits.length + 1]) {
        if (candidate.length < window) continue;
        for (int i = 0; i + window <= candidate.length; i++) {
          final sub = candidate.substring(i, i + window);
          if (_levenshtein(sub, userDigits) <= maxErrors) return true;
        }
      }
    }
    return false;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost =
            a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev.setRange(0, b.length + 1, curr);
    }
    return curr[b.length];
  }

  static DocumentValidationResult _validateDocument(String detectedText) {
    final text = detectedText.toLowerCase();
    int score = 0;
    List<String> errors = [];

    // Patrones comunes en cédulas/carnets
    final patterns = [
      // Para cédulas ecuatorianas (ajusta según tu país)
      RegExp(r'cedula|cedula|identificacion|identidad', caseSensitive: false),
      RegExp(r'bolivia|república|estado', caseSensitive: false),
      RegExp(r'[0-9]{10}'), // Número de cédula (10 dígitos)
      RegExp(r'[a-z]{1,2}[0-9]{4,10}'), // Combinación letras-números
      RegExp(r'nombres?|apellidos?|fecha|nacimiento', caseSensitive: false),
      RegExp(r'provincia|canton|ciudad', caseSensitive: false),
    ];

    // Palabras clave que NO deberían aparecer en un documento
    final invalidPatterns = [
      RegExp(r'factura|recibo|boleta|comprobante', caseSensitive: false),
      RegExp(r'pag[ao]|precio|total|importe', caseSensitive: false),
    ];

    // Verificar patrones inválidos primero
    for (final pattern in invalidPatterns) {
      if (pattern.hasMatch(text)) {
        errors.add('El contenido parece ser un documento comercial');
        score -= 30;
      }
    }

    // Verificar patrones válidos
    for (final pattern in patterns) {
      if (pattern.hasMatch(text)) {
        score += 15;
      }
    }

    // Validar longitud mínima (documentos suelen tener bastante texto)
    if (text.length < 50) {
      errors.add('El texto detectado es muy corto para ser un documento');
      score -= 20;
    }

    // Validar presencia de números (documentos tienen números)
    final digitCount = text.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount < 5) {
      errors.add('Muy pocos números detectados para ser un documento');
      score -= 15;
    }

    // Validar presencia de letras
    final letterCount = text.replaceAll(RegExp(r'[^a-záéíóúñ]'), '').length;
    if (letterCount < 20) {
      errors.add('Muy pocas letras detectadas para ser un documento');
      score -= 15;
    }

    final isValid = score >= 30 && errors.isEmpty;

    return DocumentValidationResult(
      isValid: isValid,
      score: score,
      errorMessage: isValid ? null : errors.join(', '),
    );
  }
}

class TextDetectionResult {
  final bool success;
  final bool match;
  final String detectedText;
  final String? error;
  final bool isDocumentValid;
  final int validationScore;
  final List<TextBlock> matchedBlocks;

  TextDetectionResult({
    required this.success,
    required this.match,
    required this.detectedText,
    this.error,
    required this.isDocumentValid,
    required this.validationScore,
    required this.matchedBlocks,
  });
}

class DocumentValidationResult {
  final bool isValid;
  final int score;
  final String? errorMessage;

  DocumentValidationResult({
    required this.isValid,
    required this.score,
    this.errorMessage,
  });
}
