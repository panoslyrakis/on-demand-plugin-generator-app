import 'dart:io';
import 'package:path/path.dart' as path;

class StringReplacementService {
  StringReplacementService._();
  
  /// Replace text in all files within a directory
  static Future<ReplacementResult> replaceInFiles({
    required String directoryPath,
    required String searchText,
    required String replaceText,
    List<String>? fileExtensions, // e.g., ['.dart', '.php', '.js']
    List<String>? excludePatterns, // e.g., ['.git', 'node_modules']
    Function(String)? onProgress,
  }) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return ReplacementResult(
          success: false,
          message: 'Directory does not exist: $directoryPath',
        );
      }
      
      int filesProcessed = 0;
      int replacementsMade = 0;
      final processedFiles = <String>[];
      
      onProgress?.call('Scanning directory for files...');
      
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final filePath = entity.path;
          final relativePath = path.relative(filePath, from: directoryPath);
          
          // Skip excluded patterns
          if (excludePatterns != null) {
            bool shouldSkip = false;
            for (final pattern in excludePatterns) {
              if (relativePath.contains(pattern)) {
                shouldSkip = true;
                break;
              }
            }
            if (shouldSkip) continue;
          }
          
          // Check file extension
          if (fileExtensions != null) {
            final extension = path.extension(filePath);
            if (!fileExtensions.contains(extension)) {
              continue;
            }
          }
          
          // Read and process file
          try {
            final content = await entity.readAsString();
            if (content.contains(searchText)) {
              final newContent = content.replaceAll(searchText, replaceText);
              await entity.writeAsString(newContent);
              
              final occurrences = searchText.allMatches(content).length;
              replacementsMade += occurrences;
              processedFiles.add(relativePath);
              
              onProgress?.call('Processed: $relativePath ($occurrences replacements)');
            }
            filesProcessed++;
          } catch (e) {
            onProgress?.call('Error processing $relativePath: $e');
          }
        }
      }
      
      return ReplacementResult(
        success: true,
        message: 'Replacement completed: $replacementsMade replacements in ${processedFiles.length} files',
        filesProcessed: filesProcessed,
        replacementsMade: replacementsMade,
        processedFiles: processedFiles,
      );
      
    } catch (e) {
      return ReplacementResult(
        success: false,
        message: 'Error during replacement: $e',
      );
    }
  }
  
  /// Replace multiple patterns in files
  static Future<ReplacementResult> replaceMultipleInFiles({
    required String directoryPath,
    required Map<String, String> replacements, // searchText -> replaceText
    List<String>? fileExtensions,
    List<String>? excludePatterns,
    Function(String)? onProgress,
  }) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return ReplacementResult(
          success: false,
          message: 'Directory does not exist: $directoryPath',
        );
      }
      
      int filesProcessed = 0;
      int totalReplacements = 0;
      final processedFiles = <String>[];
      
      onProgress?.call('Scanning directory for files...');
      
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final filePath = entity.path;
          final relativePath = path.relative(filePath, from: directoryPath);
          
          // Skip excluded patterns
          if (excludePatterns != null) {
            bool shouldSkip = false;
            for (final pattern in excludePatterns) {
              if (relativePath.contains(pattern)) {
                shouldSkip = true;
                break;
              }
            }
            if (shouldSkip) continue;
          }
          
          // Check file extension
          if (fileExtensions != null) {
            final extension = path.extension(filePath);
            if (!fileExtensions.contains(extension)) {
              continue;
            }
          }
          
          // Read and process file
          try {
            String content = await entity.readAsString();
            bool fileModified = false;
            int fileReplacements = 0;
            
            // Apply all replacements
            for (final entry in replacements.entries) {
              final searchText = entry.key;
              final replaceText = entry.value;
              
              if (content.contains(searchText)) {
                final occurrences = searchText.allMatches(content).length;
                content = content.replaceAll(searchText, replaceText);
                fileReplacements += occurrences;
                fileModified = true;
              }
            }
            
            // Write back if modified
            if (fileModified) {
              await entity.writeAsString(content);
              totalReplacements += fileReplacements;
              processedFiles.add(relativePath);
              onProgress?.call('Processed: $relativePath ($fileReplacements replacements)');
            }
            
            filesProcessed++;
          } catch (e) {
            onProgress?.call('Error processing $relativePath: $e');
          }
        }
      }
      
      return ReplacementResult(
        success: true,
        message: 'Multiple replacements completed: $totalReplacements total replacements in ${processedFiles.length} files',
        filesProcessed: filesProcessed,
        replacementsMade: totalReplacements,
        processedFiles: processedFiles,
      );
      
    } catch (e) {
      return ReplacementResult(
        success: false,
        message: 'Error during multiple replacements: $e',
      );
    }
  }
}

class ReplacementResult {
  final bool success;
  final String message;
  final int? filesProcessed;
  final int? replacementsMade;
  final List<String>? processedFiles;
  final String? error;
  
  ReplacementResult({
    required this.success,
    required this.message,
    this.filesProcessed,
    this.replacementsMade,
    this.processedFiles,
    this.error,
  });
}
