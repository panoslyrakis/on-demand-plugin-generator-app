class PluginData {
  const PluginData({
    required this.title,
    required this.description,
    required this.workingDirectory,
  });
  
  final String title;
  final String description;
  final String workingDirectory;
  
  bool get isValid {
    return title.trim().isNotEmpty && 
           description.trim().isNotEmpty && 
           workingDirectory.trim().isNotEmpty;
  }
  
  String? get validationError {
    if (title.trim().isEmpty) return 'Plugin title is required';
    if (description.trim().isEmpty) return 'Plugin description is required';
    if (workingDirectory.trim().isEmpty) return 'Working directory is required';
    return null;
  }
  
  Map<String, String> toMap() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'workingDirectory': workingDirectory.trim(),
    };
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluginData &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          description == other.description &&
          workingDirectory == other.workingDirectory;

  @override
  int get hashCode => title.hashCode ^ description.hashCode ^ workingDirectory.hashCode;

  @override
  String toString() => 'PluginData(title: $title, description: $description, workingDirectory: $workingDirectory)';
}