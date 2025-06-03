import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/string_case_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class StringToolsScreen extends StatefulWidget {
  const StringToolsScreen({super.key});

  @override
  State<StringToolsScreen> createState() => _StringToolsScreenState();
}

class _StringToolsScreenState extends State<StringToolsScreen> {
  final TextEditingController _inputController = TextEditingController();
  final Map<String, String> _results = {};
  bool _isConverting = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _convertString(String type) async {
    if (_inputController.text.isEmpty) return;
    
    setState(() {
      _isConverting = true;
    });

    try {
      String result;
      switch (type) {
        case 'normalize':
          result = StringCaseService.normalizeString(_inputController.text);
          break;
        case 'pascal':
          result = StringCaseService.toPascalCase(_inputController.text);
          break;
        case 'camel':
          result = StringCaseService.toCamelCase(_inputController.text);
          break;
        case 'snake':
          result = StringCaseService.toSnakeCase(_inputController.text);
          break;
        case 'kebab':
          result = StringCaseService.toKebabCase(_inputController.text);
          break;
        case 'screaming':
          result = StringCaseService.toScreamingSnakeCase(_inputController.text);
          break;
        case 'capitalize':
          result = StringCaseService.capitalizeFirst(_inputController.text);
          break;
        case 'flat':
          result = StringCaseService.toFlatCase(_inputController.text);
          break;
        case 'pascal_snake':
          result = StringCaseService.toPascalSnakeCase(_inputController.text);
          break;
        default:
          result = 'Unknown conversion type';
      }

      setState(() {
        _results[type] = result;
      });
    } catch (e) {
      _showError('Error converting string: $e');
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  Future<void> _convertAll() async {
    if (_inputController.text.isEmpty) return;

    setState(() {
      _isConverting = true;
      _results.clear();
    });

    try {
      final conversions = [
        'normalize',
        'pascal', 
        'camel',
        'snake',
        'kebab',
        'screaming',
        'capitalize',
      ];

      for (final type in conversions) {
        await _convertString(type);
        // Small delay to show progress
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      setState() {
        _isConverting = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccess('Copied to clipboard!');
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _results.clear();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorMain,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successMain,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Go Bridge Status
          _buildStatusCard(),
          
          const SizedBox(height: 16),
          
          // Input Section
          _buildInputSection(),
          
          const SizedBox(height: 16),
          
          // Conversion Buttons
          _buildConversionButtons(),
          
          const SizedBox(height: 20),
          
          // Results Section
          if (_results.isNotEmpty) _buildResultsSection(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: AppColors.successLight,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.successDark,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pure Flutter Mode - String conversion available without Go backend',
                style: TextStyle(
                  color: AppColors.successDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'String Conversion Tools',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Input Text',
                hintText: 'Enter text to convert (e.g., "hello world", "my-plugin-name")...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
                ),
              ),
              onChanged: (value) {
                // Clear results when input changes
                if (_results.isNotEmpty) {
                  setState(() {
                    _results.clear();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conversion Options:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildConversionButton('Normalize', 'normalize', Icons.cleaning_services),
                _buildConversionButton('camelCase', 'camel', Icons.text_fields),
                _buildConversionButton('PascalCase', 'pascal', Icons.title),
                _buildConversionButton('snake_case', 'snake', Icons.horizontal_rule),
                _buildConversionButton('kebab-case', 'kebab', Icons.remove),
                _buildConversionButton('SCREAMING_SNAKE', 'screaming', Icons.volume_up),
                _buildConversionButton('Capitalize First', 'capitalize', Icons.format_color_text),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConverting ? null : _convertAll,
                    icon: _isConverting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(_isConverting ? 'Converting...' : 'Convert All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.infoMain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionButton(String label, String type, IconData icon) {
    final hasResult = _results.containsKey(type);
    
    return ElevatedButton.icon(
      onPressed: _isConverting ? null : () => _convertString(type),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: hasResult ? AppColors.successMain : null,
        foregroundColor: hasResult ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._results.entries.map((entry) => _buildResultItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String type, String result) {
    String displayName;
    switch (type) {
      case 'normalize':
        displayName = 'Normalized';
        break;
      case 'pascal':
        displayName = 'PascalCase';
        break;
      case 'camel':
        displayName = 'camelCase';
        break;
      case 'snake':
        displayName = 'snake_case';
        break;
      case 'kebab':
        displayName = 'kebab-case';
        break;
      case 'screaming':
        displayName = 'SCREAMING_SNAKE_CASE';
        break;
      case 'capitalize':
        displayName = 'Capitalize First';
        break;
      default:
        displayName = type;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$displayName:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.grey300),
              ),
              child: Text(
                result,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(result),
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy to clipboard',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}