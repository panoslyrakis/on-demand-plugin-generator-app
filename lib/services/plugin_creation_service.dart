// =====================================
// lib/services/plugin_creation_service.dart
// =====================================
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/bitbucket_credentials.dart';
import '../models/plugin_data.dart';
import 'git_service.dart';
import 'string_replacement_service.dart';
import 'string_case_service.dart';

class PluginCreationService {
  PluginCreationService._();
  
  /// Complete plugin creation workflow
  static Future<PluginCreationResult> createPlugin({
    required BitbucketCredentials credentials,
    required PluginData pluginData,
    required String templateRepositoryUrl,
    Function(String)? onProgress,
  }) async {
    final steps = <String>[];
    
    try {
      steps.add('Starting plugin creation process...');
      steps.add('Username: ${credentials.username}');
      steps.add('Plugin Title: ${pluginData.title}');
      steps.add('Description: ${pluginData.description}');
      steps.add('Working Directory: ${pluginData.workingDirectory}');
      onProgress?.call(steps.join('\n'));
      
      // Step 1: Validate inputs
      steps.add('\n--- Step 1: Validation ---');
      onProgress?.call(steps.join('\n'));
      
      try {
        final validationResult = await _validateInputs(credentials, pluginData);
        if (!validationResult.success) {
          steps.add('\n--- VALIDATION FAILED ---');
          return PluginCreationResult(
            success: false,
            message: validationResult.message,
            log: steps.join('\n'),
          );
        }
        steps.add('✓ All inputs validated successfully');
        onProgress?.call(steps.join('\n'));
      } catch (e) {
        steps.add('✗ Validation crashed: $e');
        return PluginCreationResult(
          success: false,
          message: 'Validation failed: $e',
          log: steps.join('\n'),
        );
      }
      
      // Step 2: Check Git availability
      steps.add('\n--- Step 2: Git Setup ---');
      onProgress?.call(steps.join('\n'));
      
      try {
        final gitAvailable = await GitService.isGitAvailable(
          workingDirectory: pluginData.workingDirectory,
        );
        if (!gitAvailable) {
          steps.add('✗ Git not available on system');
          return PluginCreationResult(
            success: false,
            message: 'Git is not installed or not available in PATH',
            log: steps.join('\n'),
          );
        }
        
        final gitVersion = await GitService.getGitVersion();
        steps.add('✓ Git available: $gitVersion');
        onProgress?.call(steps.join('\n'));
      } catch (e) {
        steps.add('✗ Git check crashed: $e');
        return PluginCreationResult(
          success: false,
          message: 'Git check failed: $e',
          log: steps.join('\n'),
        );
      }
      
      // Step 3: Clone repository
      steps.add('\n--- Step 3: Repository Cloning ---');
      onProgress?.call(steps.join('\n'));
      
      try {
        // Create a temporary directory name for cloning
        final workingDir = Directory(pluginData.workingDirectory);
        final tempCloneName = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempClonePath = path.join(workingDir.path, tempCloneName);
        
        // Generate case variations for renaming
        final normalizedTitle = StringCaseService.normalizeString(pluginData.title);
        final caseVariations = StringCaseService.getAllCaseVariations(normalizedTitle);
        
        // Use kebab-case for the final plugin directory name
        final finalPluginPath = path.join(workingDir.path, caseVariations['kebab-case']!);
        
        steps.add('Temp clone path: $tempClonePath');
        steps.add('Final plugin path: $finalPluginPath');
        onProgress?.call(steps.join('\n'));
        
        final cloneResult = await GitService.cloneRepositoryWithProcess(
          repositoryUrl: templateRepositoryUrl,
          destinationPath: tempClonePath,
          username: credentials.username,
          password: credentials.password,
          onProgress: (message) {
            steps.add(message);
            onProgress?.call(steps.join('\n'));
          },
        );
        
        if (!cloneResult.success) {
          steps.add('✗ Repository cloning failed');
          return PluginCreationResult(
            success: false,
            message: cloneResult.message,
            log: steps.join('\n'),
          );
        }
        
        // Rename the cloned directory to the plugin name
        try {
          final tempDir = Directory(tempClonePath);
          if (await tempDir.exists()) {
            await tempDir.rename(finalPluginPath);
            steps.add('✓ Repository cloned and renamed successfully');
            
            // Check if the cloned directory itself needs renaming based on template name
            final clonedContents = await Directory(finalPluginPath).list().toList();
            for (final entity in clonedContents) {
              if (entity is Directory) {
                final dirName = path.basename(entity.path);
                // Check if this is the main plugin directory that needs renaming
                if (dirName.contains('on-demand') || dirName.contains('wpmudev')) {
                  final newDirName = caseVariations['kebab-case']!;
                  final newDirPath = path.join(finalPluginPath, newDirName);
                  try {
                    await entity.rename(newDirPath);
                    steps.add('✓ Renamed main plugin directory: $dirName → $newDirName');
                  } catch (e) {
                    steps.add('⚠ Warning: Could not rename main plugin directory: $e');
                  }
                  break;
                }
              }
            }
          } else {
            steps.add('✗ Temp directory not found after clone');
            return PluginCreationResult(
              success: false,
              message: 'Cloned directory not found at: $tempClonePath',
              log: steps.join('\n'),
            );
          }
        } catch (e) {
          steps.add('✗ Failed to rename cloned directory: $e');
          return PluginCreationResult(
            success: false,
            message: 'Failed to rename cloned directory: $e',
            log: steps.join('\n'),
          );
        }
        
        onProgress?.call(steps.join('\n'));
        
        // Step 4: Generate replacement mappings
        steps.add('\n--- Step 4: Generating Replacements ---');
        onProgress?.call(steps.join('\n'));
        
        final replacements = _generateReplacements(pluginData);
        steps.add('✓ Generated ${replacements.length} replacement patterns');
        onProgress?.call(steps.join('\n'));
        
        // Step 5: Replace content in files
        steps.add('\n--- Step 5: Content Replacement ---');
        onProgress?.call(steps.join('\n'));
        
        final replacementResult = await StringReplacementService.replaceMultipleInFiles(
          directoryPath: finalPluginPath,
          replacements: replacements,
          fileExtensions: ['.php', '.js', '.css', '.html', '.txt', '.md', '.json', '.xml', '.yaml', '.yml'],
          excludePatterns: ['.git', 'node_modules', '.DS_Store', '__pycache__', '.vscode', '.idea'],
          onProgress: (message) {
            steps.add(message);
            onProgress?.call(steps.join('\n'));
          },
        );
        
        if (!replacementResult.success) {
          steps.add('✗ Content replacement failed');
          return PluginCreationResult(
            success: false,
            message: replacementResult.message,
            log: steps.join('\n'),
          );
        }
        steps.add('✓ Content replacement completed');
        steps.add('  Files processed: ${replacementResult.filesProcessed}');
        steps.add('  Replacements made: ${replacementResult.replacementsMade}');
        onProgress?.call(steps.join('\n'));
        
        // Step 6: Rename files and directories
        steps.add('\n--- Step 6: File/Directory Renaming ---');
        onProgress?.call(steps.join('\n'));
        
        final renameResult = await _renameFilesAndDirectories(
          finalPluginPath,
          pluginData.title,
          onProgress: (message) {
            steps.add(message);
            onProgress?.call(steps.join('\n'));
          },
        );
        
        if (!renameResult.success) {
          steps.add('✗ File/directory renaming failed');
          return PluginCreationResult(
            success: false,
            message: renameResult.message,
            log: steps.join('\n'),
          );
        }
        steps.add('✓ File/directory renaming completed');
        steps.add('  Files/directories renamed: ${renameResult.renamedCount}');
        onProgress?.call(steps.join('\n'));
        
        // Step 7: Clean up
        steps.add('\n--- Step 7: Cleanup ---');
        onProgress?.call(steps.join('\n'));
        
        await _cleanupRepository(finalPluginPath);
        steps.add('✓ Repository cleanup completed');
        onProgress?.call(steps.join('\n'));
        
        // Step 8: Generate summary
        steps.add('\n--- Step 8: Summary ---');
        final summary = await _generateSummary(finalPluginPath);
        steps.addAll(summary);
        onProgress?.call(steps.join('\n'));
        
        // Success!
        steps.add('\n🎉 SUCCESS: Plugin "${pluginData.title}" created successfully!');
        steps.add('📍 Location: $finalPluginPath');
        onProgress?.call(steps.join('\n'));
        
        return PluginCreationResult(
          success: true,
          message: 'Plugin "${pluginData.title}" created successfully in $finalPluginPath',
          log: steps.join('\n'),
          outputPath: finalPluginPath,
        );
        
      } catch (e) {
        steps.add('✗ Repository cloning crashed: $e');
        return PluginCreationResult(
          success: false,
          message: 'Repository cloning failed: $e',
          log: steps.join('\n'),
        );
      }
      
    } catch (e) {
      steps.add('\n✗ FATAL ERROR: $e');
      return PluginCreationResult(
        success: false,
        message: 'Fatal error during plugin creation: $e',
        log: steps.join('\n'),
      );
    }
  }
  
  /// Validate all inputs
  static Future<ValidationResult> _validateInputs(
    BitbucketCredentials credentials,
    PluginData pluginData,
  ) async {
    // Check credentials
    if (!credentials.isValid) {
      return ValidationResult(
        success: false,
        message: 'Invalid Bitbucket credentials',
      );
    }
    
    // Check plugin data
    if (!pluginData.isValid) {
      return ValidationResult(
        success: false,
        message: pluginData.validationError ?? 'Invalid plugin data',
      );
    }
    
    // Check working directory
    final workingDir = Directory(pluginData.workingDirectory);
    if (!await workingDir.exists()) {
      // Try to create the working directory
      try {
        await workingDir.create(recursive: true);
      } catch (e) {
        return ValidationResult(
          success: false,
          message: 'Cannot create working directory: ${workingDir.path} - $e',
        );
      }
    }

    // Check if plugin directory already exists (using kebab-case name)
    final normalizedTitle = StringCaseService.normalizeString(pluginData.title);
    final caseVariations = StringCaseService.getAllCaseVariations(normalizedTitle);
    final pluginDir = Directory(path.join(workingDir.path, caseVariations['kebab-case']!));
    if (await pluginDir.exists()) {
      return ValidationResult(
        success: false,
        message: 'Plugin directory already exists: ${pluginDir.path}',
      );
    }
    
    return ValidationResult(success: true, message: 'All validations passed');
  }
  
  /// Generate replacement mappings for all case variations
  static Map<String, String> _generateReplacements(PluginData pluginData) {
    final normalizedTitle = StringCaseService.normalizeString(pluginData.title);
    final caseVariations = StringCaseService.getAllCaseVariations(normalizedTitle);
    
    final replacements = <String, String>{};
    
    // Specific template patterns from your on-demand plugin
    replacements['On Demand'] = _capitalizeFirst(pluginData.title);
    replacements['On Demand plugin description.'] = pluginData.description;
    replacements['wpmudev-on-demand'] = caseVariations['kebab-case']!;
    replacements['ON_DEMAND'] = caseVariations['SCREAMING_SNAKE_CASE']!;
    replacements['OnDemand'] = caseVariations['PascalCase']!;
    replacements['onDemand'] = caseVariations['camelCase']!;
    replacements['on_demand'] = caseVariations['snake_case']!;
    
    // Additional common placeholder patterns
    const placeholderPatterns = [
      'PLUGIN_NAME',
      'PLUGIN_TITLE', 
      'PluginName',
      'plugin_name',
      'plugin-name',
      'pluginname',
      'PLUGINNAME',
      'Plugin_Name',
      'MY_PLUGIN',
      'MyPlugin',
      'my_plugin',
      'my-plugin',
      'TEMPLATE_NAME',
      'TemplateName',
      'template_name',
      'template-name',
    ];
    
    // Generate replacements for each placeholder pattern
    for (final placeholder in placeholderPatterns) {
      final placeholderVariations = StringCaseService.getAllCaseVariations(placeholder);
      
      // Map each placeholder variation to the corresponding title variation
      replacements[placeholderVariations['PascalCase']!] = caseVariations['PascalCase']!;
      replacements[placeholderVariations['camelCase']!] = caseVariations['camelCase']!;
      replacements[placeholderVariations['snake_case']!] = caseVariations['snake_case']!;
      replacements[placeholderVariations['kebab-case']!] = caseVariations['kebab-case']!;
      replacements[placeholderVariations['SCREAMING_SNAKE_CASE']!] = caseVariations['SCREAMING_SNAKE_CASE']!;
      replacements[placeholderVariations['flatcase']!] = caseVariations['flatcase']!;
      replacements[placeholderVariations['Pascal_Snake_Case']!] = caseVariations['Pascal_Snake_Case']!;
    }
    
    // Add description replacements
    const descriptionPlaceholders = [
      'PLUGIN_DESCRIPTION',
      'Plugin Description',
      'plugin_description',
      'plugin-description',
      'MY_PLUGIN_DESCRIPTION',
      'My Plugin Description',
      'TEMPLATE_DESCRIPTION',
      'Template Description',
    ];
    
    for (final placeholder in descriptionPlaceholders) {
      replacements[placeholder] = pluginData.description;
    }
    
    // Add author placeholders (you can extend this)
    replacements['AUTHOR_NAME'] = 'Plugin Author';
    replacements['AUTHOR_EMAIL'] = 'author@example.com';
    
    return replacements;
  }
  
  /// Capitalize first letter of each word
  static String _capitalizeFirst(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Rename files and directories containing placeholder names
  static Future<RenameResult> _renameFilesAndDirectories(
    String directoryPath,
    String title,
    {Function(String)? onProgress}
  ) async {
    try {
      final directory = Directory(directoryPath);
      final normalizedTitle = StringCaseService.normalizeString(title);
      final caseVariations = StringCaseService.getAllCaseVariations(normalizedTitle);
      
      int renamedCount = 0;
      
      // Get all files and directories
      final entities = await directory.list(recursive: true).toList();
      
      // Sort by depth (deepest first) to avoid path conflicts
      entities.sort((a, b) => b.path.split(path.separator).length.compareTo(a.path.split(path.separator).length));
      
      for (final entity in entities) {
        final currentPath = entity.path;
        final relativePath = path.relative(currentPath, from: directoryPath);
        
        // Skip .git directory and other VCS directories
        if (relativePath.contains('.git') || 
            relativePath.contains('.svn') || 
            relativePath.contains('.hg')) continue;
        
        String newPath = currentPath;
        bool needsRename = false;
        
        // Check for specific template file names first
        final fileName = path.basename(currentPath);
        
        // Handle specific main plugin file
        if (fileName == 'on-demand.php') {
          final newFileName = '${caseVariations['kebab-case']}.php';
          newPath = path.join(path.dirname(currentPath), newFileName);
          needsRename = true;
          onProgress?.call('Renaming main plugin file: $fileName → $newFileName');
        }
        // Handle other specific files
        else if (fileName.contains('on-demand')) {
          final newFileName = fileName.replaceAll('on-demand', caseVariations['kebab-case']!);
          newPath = path.join(path.dirname(currentPath), newFileName);
          needsRename = true;
          onProgress?.call('Renaming template file: $fileName → $newFileName');
        }
        // Handle directories with template names
        else if (fileName.contains('on_demand')) {
          final newFileName = fileName.replaceAll('on_demand', caseVariations['snake_case']!);
          newPath = path.join(path.dirname(currentPath), newFileName);
          needsRename = true;
          onProgress?.call('Renaming template directory: $fileName → $newFileName');
        }
        // Check for common placeholder patterns in the path
        else {
          final placeholderPatterns = [
            'plugin_name',
            'plugin-name', 
            'pluginname',
            'PluginName',
            'PLUGIN_NAME',
            'my_plugin',
            'my-plugin',
            'MyPlugin',
            'template_name',
            'template-name',
            'TemplateName',
            'OnDemand',
            'onDemand',
            'ON_DEMAND',
          ];
          
          for (final placeholder in placeholderPatterns) {
            if (fileName.toLowerCase().contains(placeholder.toLowerCase())) {
              final placeholderVariations = StringCaseService.getAllCaseVariations(placeholder);
              
              String newBasename = fileName;
              
              // Replace with appropriate case variation based on the original pattern
              for (final entry in placeholderVariations.entries) {
                final placeholderVariation = entry.value;
                if (newBasename.contains(placeholderVariation)) {
                  final replacement = caseVariations[entry.key] ?? caseVariations['snake_case']!;
                  newBasename = newBasename.replaceAll(placeholderVariation, replacement);
                  needsRename = true;
                  break;
                }
              }
              
              if (needsRename) {
                newPath = path.join(path.dirname(currentPath), newBasename);
                break;
              }
            }
          }
        }
        
        // Perform rename if needed
        if (needsRename && newPath != currentPath) {
          try {
            await entity.rename(newPath);
            renamedCount++;
            onProgress?.call('Renamed: ${path.basename(currentPath)} → ${path.basename(newPath)}');
          } catch (e) {
            onProgress?.call('Failed to rename ${path.basename(currentPath)}: $e');
          }
        }
      }
      
      return RenameResult(
        success: true,
        message: 'Renamed $renamedCount files/directories',
        renamedCount: renamedCount,
      );
      
    } catch (e) {
      return RenameResult(
        success: false,
        message: 'Error during renaming: $e',
      );
    }
  }
  
  /// Clean up repository (remove .git, etc.)
  static Future<void> _cleanupRepository(String directoryPath) async {
    try {
      // Remove .git directory
      final gitDir = Directory(path.join(directoryPath, '.git'));
      if (await gitDir.exists()) {
        await gitDir.delete(recursive: true);
      }
      
      // Remove other common VCS directories
      final vcsDirectories = ['.svn', '.hg', '.bzr'];
      for (final vcsDir in vcsDirectories) {
        final dir = Directory(path.join(directoryPath, vcsDir));
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
      
    } catch (e) {
      // Cleanup errors are non-fatal
      print('Warning: Cleanup error: $e');
    }
  }
  
  /// Generate a summary of the created plugin
  static Future<List<String>> _generateSummary(String directoryPath) async {
    final summary = <String>[];
    
    try {
      final directory = Directory(directoryPath);
      
      // Count files by type
      final fileCounts = <String, int>{};
      int totalFiles = 0;
      int totalSize = 0;
      
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalFiles++;
          final extension = path.extension(entity.path);
          fileCounts[extension] = (fileCounts[extension] ?? 0) + 1;
          
          try {
            final stat = await entity.stat();
            totalSize += stat.size;
          } catch (e) {
            // Ignore stat errors
          }
        }
      }
      
      summary.add('📊 Plugin Summary:');
      summary.add('  • Total files: $totalFiles');
      summary.add('  • Total size: ${_formatFileSize(totalSize)}');
      
      if (fileCounts.isNotEmpty) {
        summary.add('  • File types:');
        final sortedCounts = fileCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        for (final entry in sortedCounts.take(5)) {
          final ext = entry.key.isEmpty ? 'no extension' : entry.key;
          summary.add('    - $ext: ${entry.value} files');
        }
      }
      
    } catch (e) {
      summary.add('📊 Plugin Summary: Unable to generate summary ($e)');
    }
    
    return summary;
  }
  
  /// Format file size in human readable format
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// Result classes
class PluginCreationResult {
  final bool success;
  final String message;
  final String log;
  final String? outputPath;
  final String? error;
  
  PluginCreationResult({
    required this.success,
    required this.message,
    required this.log,
    this.outputPath,
    this.error,
  });
  
  @override
  String toString() {
    return 'PluginCreationResult(success: $success, message: $message)';
  }
}

class ValidationResult {
  final bool success;
  final String message;
  
  ValidationResult({
    required this.success,
    required this.message,
  });
  
  @override
  String toString() {
    return 'ValidationResult(success: $success, message: $message)';
  }
}

class RenameResult {
  final bool success;
  final String message;
  final int? renamedCount;
  
  RenameResult({
    required this.success,
    required this.message,
    this.renamedCount,
  });
  
  @override
  String toString() {
    return 'RenameResult(success: $success, message: $message, renamedCount: $renamedCount)';
  }
}