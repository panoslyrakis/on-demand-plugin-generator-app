import 'dart:io';
import 'package:git/git.dart';

class GitService {
  GitService._();
  
  /// Clone a repository using system git (with proper PATH)
  static Future<GitCloneResult> cloneRepositoryWithProcess({
    required String repositoryUrl,
    required String destinationPath,
    required String username,
    required String password,
    Function(String)? onProgress,
  }) async {
    try {
      // Clean destination
      final destDir = Directory(destinationPath);
      if (await destDir.exists()) {
        await destDir.delete(recursive: true);
      }
      
      onProgress?.call('Initializing git clone...');
      
      // Create parent directory if it doesn't exist
      final parentDir = destDir.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      
      // Build authenticated URL
      final uri = Uri.parse(repositoryUrl);
      final authenticatedUrl = '${uri.scheme}://$username:$password@${uri.host}${uri.path}';
      
      onProgress?.call('Cloning repository...');
      
      // Find git executable
      final gitPath = await _findGitExecutable();
      if (gitPath == null) {
        return GitCloneResult(
          success: false,
          message: 'Git executable not found',
        );
      }
      
      // Set environment with expanded PATH and network settings
      final environment = Map<String, String>.from(Platform.environment);
      environment['PATH'] = '${environment['PATH']}:/usr/local/bin:/opt/homebrew/bin:/usr/bin';
      
      // Add git configuration for network issues
      environment['GIT_SSL_NO_VERIFY'] = 'false';
      environment['GIT_CURL_VERBOSE'] = '1';
      
      // Run git clone command with timeout
      final result = await Process.run(
        gitPath,
        [
          'clone',
          '--verbose',
          '--progress',
          authenticatedUrl,
          destinationPath,
        ],
        environment: environment,
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () => ProcessResult(0, 124, '', 'Git clone timed out after 5 minutes'),
      );
      
      if (result.exitCode == 0) {
        onProgress?.call('Repository cloned successfully');
        return GitCloneResult(
          success: true,
          message: 'Repository cloned successfully',
          localPath: destinationPath,
        );
      } else {
        final errorOutput = result.stderr.toString();
        final stdOutput = result.stdout.toString();
        
        // Provide more specific error messages
        String errorMessage = 'Git clone failed';
        if (errorOutput.contains('443') || errorOutput.contains('timeout')) {
          errorMessage = 'Network connection failed. Check your internet connection and repository URL.';
        } else if (errorOutput.contains('Authentication failed') || errorOutput.contains('403')) {
          errorMessage = 'Authentication failed. Check your username and password/app password.';
        } else if (errorOutput.contains('not found') || errorOutput.contains('404')) {
          errorMessage = 'Repository not found. Check the repository URL.';
        }
        
        return GitCloneResult(
          success: false,
          message: '$errorMessage\nDetails: $errorOutput\nOutput: $stdOutput',
        );
      }
    } catch (e) {
      return GitCloneResult(
        success: false,
        message: 'Error during git clone: $e',
      );
    }
  }
  
  /// Find git executable in common locations
  /// Find git executable in common locations
static Future<String?> _findGitExecutable() async {
  List<String> gitPaths;
  
  // Platform-specific git paths
  if (Platform.isMacOS) {
    gitPaths = [
      'git', // Default PATH
      '/usr/bin/git', // System Git
      '/usr/local/bin/git', // Homebrew Git
      '/opt/homebrew/bin/git', // Apple Silicon Homebrew
      '/Applications/Xcode.app/Contents/Developer/usr/bin/git', // Xcode Git
    ];
  } else if (Platform.isWindows) {
    gitPaths = [
      'git', // Default PATH
      'git.exe', // Default PATH with extension
      r'C:\Program Files\Git\bin\git.exe',
      r'C:\Program Files (x86)\Git\bin\git.exe',
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'user'}\\AppData\\Local\\Programs\\Git\\bin\\git.exe',
      r'C:\msys64\usr\bin\git.exe', // MSYS2
      r'C:\Git\bin\git.exe', // Portable Git
    ];
  } else if (Platform.isLinux) {
    gitPaths = [
      'git', // Default PATH
      '/usr/bin/git', // System Git
      '/usr/local/bin/git', // User installed
      '/bin/git', // Alternative system location
      '/snap/bin/git', // Snap package
      '/usr/local/git/bin/git', // Custom installation
    ];
  } else {
    // Fallback for other platforms
    gitPaths = ['git'];
  }
  
  print('GIT SERVICE: gitPaths = $gitPaths');
  
  for (final gitPath in gitPaths) {
    try {
      print('GIT SERVICE: CHECKING PATH = $gitPath');
      
      // Add timeout to prevent hanging
      final result = await Process.run(gitPath, ['--version']).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('GIT SERVICE: TIMEOUT for path = $gitPath');
          return ProcessResult(0, 124, '', 'Timeout checking git version');
        },
      );

      if (result.exitCode == 0) {
        print('GIT SERVICE: SUCCESS for path = $gitPath');
        print('GIT SERVICE: Version output = ${result.stdout}');
        return gitPath;
      } else {
        print('GIT SERVICE: FAILED for path = $gitPath, exitCode = ${result.exitCode}');
        print('GIT SERVICE: Error = ${result.stderr}');
      }
    } catch (e, stackTrace) {
      print('GIT SERVICE: EXCEPTION for path = $gitPath: $e');
      print('GIT SERVICE: Stack trace = $stackTrace');
      // Continue to next path
    }
  }
  
  print('GIT SERVICE: No git executable found');
  return null;
}
  
  /// Check if git is available on the system
static Future<bool> isGitAvailable({String? workingDirectory}) async {
  print('GIT SERVICE: isGitAvailable in directory: $workingDirectory');
  
  try {
    // First, just check if git works at all (without specifying working directory)
    print('GIT SERVICE: Testing basic git availability');
    try {
      final basicResult = await Process.run('git', ['--version']).timeout(
        const Duration(seconds: 5),
      );
      if (basicResult.exitCode == 0) {
        print('GIT SERVICE: Basic git test SUCCESS: ${basicResult.stdout.trim()}');
        // If basic git works, return true for now
        // We can do more specific directory testing later if needed
        return true;
      } else {
        print('GIT SERVICE: Basic git test FAILED, exitCode: ${basicResult.exitCode}');
        print('GIT SERVICE: Basic git STDERR: ${basicResult.stderr}');
        print('GIT SERVICE: Basic git STDOUT: ${basicResult.stdout}');
      }
    } catch (e) {
      print('GIT SERVICE: Basic git test EXCEPTION: $e');
    }
    
    // If basic git fails, try finding git executable
    print('GIT SERVICE: Basic git failed, trying to find git executable');
    final gitPath = await _findGitExecutable();
    print('GIT SERVICE: gitPath = $gitPath');
    
    if (gitPath != null) {
      return true;
    }
    
    // Final fallback: try platform-specific command to locate git
    print('GIT SERVICE: Trying fallback command to locate git');
    try {
      final locateCommand = Platform.isWindows ? 'where' : 'which';
      final locateResult = await Process.run(locateCommand, ['git']).timeout(
        const Duration(seconds: 3),
      );
      if (locateResult.exitCode == 0) {
        print('GIT SERVICE: $locateCommand git found: ${locateResult.stdout}');
        return true;
      }
    } catch (e) {
      print('GIT SERVICE: locateCommand command failed: $e');
    }
    
    return false;
  } catch (e, stackTrace) {
    print('GIT SERVICE: isGitAvailable exception: $e');
    print('GIT SERVICE: Stack trace: $stackTrace');
    return false;
  }
}
  
  /// Get git version
  static Future<String?> getGitVersion() async {
    try {
      final gitPath = await _findGitExecutable();
      if (gitPath == null) return null;
      
      final result = await Process.run(gitPath, ['--version']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      // Git not available
    }
    return null;
  }
  
  /// Initialize a new git repository
  static Future<bool> initRepository(String directoryPath) async {
    try {
      await GitDir.init(directoryPath);
      return true;
    } catch (e) {
      // Fallback to Process.run if git package fails
      try {
        final gitPath = await _findGitExecutable();
        if (gitPath == null) return false;
        
        final result = await Process.run(
          gitPath,
          ['init'],
          workingDirectory: directoryPath,
        );
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
  }
  
  /// Add all files to git staging
  static Future<bool> addAllFiles(String directoryPath) async {
    try {
      final gitDir = await GitDir.fromExisting(directoryPath);
      await gitDir.runCommand(['add', '.']);
      return true;
    } catch (e) {
      // Fallback to Process.run
      try {
        final gitPath = await _findGitExecutable();
        if (gitPath == null) return false;
        
        final result = await Process.run(
          gitPath,
          ['add', '.'],
          workingDirectory: directoryPath,
        );
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
  }
  
  /// Commit changes
  static Future<bool> commit(String directoryPath, String message) async {
    try {
      final gitDir = await GitDir.fromExisting(directoryPath);
      await gitDir.runCommand(['commit', '-m', message]);
      return true;
    } catch (e) {
      // Fallback to Process.run
      try {
        final gitPath = await _findGitExecutable();
        if (gitPath == null) return false;
        
        final result = await Process.run(
          gitPath,
          ['commit', '-m', message],
          workingDirectory: directoryPath,
        );
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
  }
  
  /// Set git config for user
  static Future<bool> setUserConfig(String directoryPath, String name, String email) async {
    try {
      final gitDir = await GitDir.fromExisting(directoryPath);
      await gitDir.runCommand(['config', 'user.name', name]);
      await gitDir.runCommand(['config', 'user.email', email]);
      return true;
    } catch (e) {
      // Fallback to Process.run
      try {
        final gitPath = await _findGitExecutable();
        if (gitPath == null) return false;
        
        final nameResult = await Process.run(
          gitPath,
          ['config', 'user.name', name],
          workingDirectory: directoryPath,
        );
        
        final emailResult = await Process.run(
          gitPath,
          ['config', 'user.email', email],
          workingDirectory: directoryPath,
        );
        
        return nameResult.exitCode == 0 && emailResult.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
  }
  
  /// Check repository status
  static Future<String?> getRepositoryStatus(String directoryPath) async {
    try {
      final gitDir = await GitDir.fromExisting(directoryPath);
      final result = await gitDir.runCommand(['status', '--porcelain']);
      return result.stdout;
    } catch (e) {
      return null;
    }
  }
  
  /// Get current branch name
  static Future<String?> getCurrentBranch(String directoryPath) async {
    try {
      final gitDir = await GitDir.fromExisting(directoryPath);
      final result = await gitDir.runCommand(['branch', '--show-current']);
      return result.stdout.trim();
    } catch (e) {
      return null;
    }
  }
  
  /// Get repository remote URL
  static Future<String?> getRemoteUrl(String directoryPath) async {
    try {
      final gitDir = await GitDir.fromExisting(directoryPath);
      final result = await gitDir.runCommand(['remote', 'get-url', 'origin']);
      return result.stdout.trim();
    } catch (e) {
      return null;
    }
  }
}

class GitCloneResult {
  final bool success;
  final String message;
  final String? localPath;
  final String? error;
  
  GitCloneResult({
    required this.success,
    required this.message,
    this.localPath,
    this.error,
  });
  
  @override
  String toString() {
    return 'GitCloneResult(success: $success, message: $message, localPath: $localPath)';
  }
}