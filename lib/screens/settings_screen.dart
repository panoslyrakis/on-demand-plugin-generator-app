import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/bitbucket_credentials.dart';
import '../widgets/instruction_card.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key, 
    required this.onCredentialsUpdated,
  });
  
  final VoidCallback onCredentialsUpdated;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _credentialsSaved = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final credentials = await StorageService.loadBitbucketCredentials();
      if (mounted) {
        setState(() {
          _usernameController.text = credentials.username;
          _passwordController.text = credentials.password;
          _credentialsSaved = credentials.isValid;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error loading credentials: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credentials = BitbucketCredentials(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      await StorageService.saveBitbucketCredentials(credentials);
      
      if (mounted) {
        setState(() {
          _credentialsSaved = true;
        });
        
        widget.onCredentialsUpdated();
        _showSuccess('Credentials saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error saving credentials: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearCredentials() async {
    final confirmed = await _showConfirmDialog(
      'Clear Credentials',
      'Are you sure you want to clear your saved credentials?',
    );
    
    if (!confirmed) return;

    try {
      await StorageService.clearBitbucketCredentials();
      if (mounted) {
        setState(() {
          _usernameController.clear();
          _passwordController.clear();
          _credentialsSaved = false;
        });
        
        widget.onCredentialsUpdated();
        _showSuccess('Credentials cleared successfully');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error clearing credentials: $e');
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
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
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('Loading credentials...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCredentialsCard(),
            const SizedBox(height: 20),
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(),
            const SizedBox(height: 24),
            _buildUsernameField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      children: [
        const Icon(Icons.account_circle, color: AppConstants.infoColor, size: 28),
        const SizedBox(width: 12),
        Text(
          'Bitbucket Credentials',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_credentialsSaved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.successColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Saved',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'Bitbucket Username',
        hintText: 'Enter your Bitbucket username',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
        ),
      ),
      validator: Validators.validateUsername,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_showPassword,
      decoration: InputDecoration(
        labelText: 'Bitbucket App Password',
        hintText: 'Enter your Bitbucket app password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
        ),
      ),
      validator: Validators.validatePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveCredentials(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveCredentials,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save Credentials'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.infoColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppConstants.buttonHeight),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _credentialsSaved ? _clearCredentials : null,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.buttonHeight),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return const InstructionCard(
      title: 'How to get Bitbucket App Password',
      instructions: [
        'Go to your Bitbucket account settings',
        'Navigate to "App passwords" section',
        'Click "Create app password"',
        'Give it a name and select required permissions',
        'Copy the generated password and paste it above',
      ],
      warningMessage: 'Keep your app password secure. It will be stored locally on your device.',
    );
  }
}