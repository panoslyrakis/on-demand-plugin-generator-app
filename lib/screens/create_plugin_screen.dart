import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../services/plugin_creation_service.dart';
import '../models/plugin_data.dart';
import '../widgets/status_banner.dart';
import '../widgets/process_log_card.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class CreatePluginScreen extends StatefulWidget {
  const CreatePluginScreen({
    super.key,
    required this.hasCredentials,
  });
  
  final bool hasCredentials;

  @override
  State<CreatePluginScreen> createState() => _CreatePluginScreenState();
}

class _CreatePluginScreenState extends State<CreatePluginScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _workingDirController = TextEditingController();
  final TextEditingController _repoUrlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isProcessing = false;
  String _processResult = '';

  @override
  void initState() {
    super.initState();
    // Set default template repository URL.
    _repoUrlController.text = 'https://bitbucket.org/incsub/scaffold-plugin.git';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _workingDirController.dispose();
    _repoUrlController.dispose();
    super.dispose();
  }

  Widget _buildRepositoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Template Repository',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _repoUrlController,
              decoration: const InputDecoration(
                labelText: 'ODD Repository URL',
                hintText: 'https://bitbucket.org/incsub/scaffold-plugin.git',
                prefixIcon: Icon(Icons.source),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
                ),
                helperText: 'Bitbucket repository containing your plugin template',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Repository URL is required';
                }
                if (!value.contains('bitbucket.org') && !value.contains('.git')) {
                  return 'Please enter a valid Bitbucket repository URL';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectWorkingDirectory() async {
    print('DEBUG: _createPlugin() called');

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null && mounted) {
      setState(() {
        _workingDirController.text = selectedDirectory;
      });
    }




    } catch (e) {
      _showError('Failed to select directory: $e');
    }
    print('DEBUG: Selected directory: ${_workingDirController.text}');
  }

  Future<void> _createPlugin() async {
    if (!widget.hasCredentials) {
      print('DEBUG: No credentials');
      _showError('Please set up your Bitbucket credentials in the Settings tab first');
      return;
    }

    print('DEBUG: HAS credentials');

    if (!_formKey.currentState!.validate()) {
      print('DEBUG: SOMETHING WRONG WITH THE FORM KEY');
      return;
    }

    final pluginData = PluginData(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      workingDirectory: _workingDirController.text.trim(),
    );

    final validationError = pluginData.validationError;
    if (validationError != null) {
      print('DEBUG: VALIDATION ERROR');
      _showError(validationError);
      return;
    }

    print('CHECKPOINT : FLAG IS_PROCESSING');

    setState(() {
      _isProcessing = true;
      _processResult = '';
    });

    try {
      // Load credentials
      final credentials = await StorageService.loadBitbucketCredentials();
      print('CHECKPOINT : FLAG _processResult');
      setState(() {
        _processResult = 'Starting plugin creation with real Git operations...\n';
      });
      
      // Call real Flutter plugin creation service
      final result = await PluginCreationService.createPlugin(
        credentials: credentials,
        pluginData: pluginData,
        templateRepositoryUrl: _repoUrlController.text.trim(),
        onProgress: (log) {
          if (mounted) {
            setState(() {
              _processResult = log;
            });
          }
        },
      );
      print('CHECKPOINT : FLAG result $result');
      if (result.success) {
        _showSuccess('Plugin created successfully!');
      } else {

        print('DEBUG : BAD RESULTS $result.message');
        _showError(result.message);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _processResult += '\nError: $e';
        });
        _showError('Failed to create plugin: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _workingDirController.clear();
      _processResult = '';
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            if (!widget.hasCredentials)
              Column(
                children: [
                  StatusBanner.warning(
                    'Please set up your Bitbucket credentials in the Settings tab before creating a plugin.',
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Repository Configuration
            _buildRepositoryCard(),
            
            const SizedBox(height: 16),

            // Plugin Information Card
            _buildPluginInformationCard(),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            _buildActionButtons(),
            
            // Process Log
            if (_processResult.isNotEmpty) ...[
              const SizedBox(height: 20),
              ProcessLogCard(
                logContent: _processResult,
                isLoading: _isProcessing,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPluginInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plugin Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Plugin Title Field
            _buildPluginTitleField(),
            
            const SizedBox(height: 16),
            
            // Plugin Description Field
            _buildPluginDescriptionField(),
            
            const SizedBox(height: 16),
            
            // Working Directory Field
            _buildWorkingDirectoryField(),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Plugin Title',
        hintText: 'Enter the plugin title',
        prefixIcon: Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
        ),
      ),
      validator: Validators.validatePluginTitle,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        // You can add real-time preview of normalized title here when Go FFI is ready
        if (value.isNotEmpty) {
          // final normalized = GoBridgeService.normalizeString(value);
          // Show preview somehow
        }
      },
    );
  }

  Widget _buildPluginDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Plugin Description',
        hintText: 'Enter a description for your plugin',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
        ),
        alignLabelWithHint: true,
      ),
      validator: Validators.validatePluginDescription,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildWorkingDirectoryField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _workingDirController,
            decoration: const InputDecoration(
              labelText: 'Working Directory',
              hintText: 'Select working directory',
              prefixIcon: Icon(Icons.folder),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              ),
            ),
            readOnly: true,
            validator: Validators.validateWorkingDirectory,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _selectWorkingDirectory,
          icon: const Icon(Icons.folder_open),
          label: const Text('Browse'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: (!widget.hasCredentials || _isProcessing) ? null : _createPlugin,
            icon: _isProcessing 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.build),
            label: Text(
              _isProcessing ? 'Creating Plugin...' : 'Create Plugin',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.infoMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _clearForm,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}