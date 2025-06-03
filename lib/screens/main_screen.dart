import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';
import 'create_plugin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasCredentials = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkCredentials();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _checkCredentials() async {
    final hasCredentials = await StorageService.hasValidCredentials();
    if (mounted) {
      setState(() {
        _hasCredentials = hasCredentials;
      });
    }
  }
  
  void _onCredentialsUpdated() {
    _checkCredentials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        backgroundColor: AppConstants.infoColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.add_circle), text: 'Create Plugin'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.defaultPadding),
            child: Center(
              child: _buildStatusIndicator(),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SettingsScreen(onCredentialsUpdated: _onCredentialsUpdated),
          CreatePluginScreen(hasCredentials: _hasCredentials),
        ],
      ),
    );
  }
  
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _hasCredentials ? AppConstants.successColor : AppConstants.warningColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hasCredentials ? Icons.check_circle : Icons.warning,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _hasCredentials ? 'Ready' : 'Setup',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}