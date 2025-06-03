import 'package:shared_preferences/shared_preferences.dart';
import '../models/bitbucket_credentials.dart';
import '../utils/constants.dart';

class StorageService {
  // Prevent instantiation
  StorageService._();
  
  static Future<void> saveBitbucketCredentials(BitbucketCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.bitbucketUsernameKey, credentials.username);
    await prefs.setString(AppConstants.bitbucketPasswordKey, credentials.password);
  }
  
  static Future<BitbucketCredentials> loadBitbucketCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(AppConstants.bitbucketUsernameKey) ?? '';
    final password = prefs.getString(AppConstants.bitbucketPasswordKey) ?? '';
    
    return BitbucketCredentials(username: username, password: password);
  }
  
  static Future<bool> hasValidCredentials() async {
    final credentials = await loadBitbucketCredentials();
    return credentials.isValid;
  }
  
  static Future<void> clearBitbucketCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.bitbucketUsernameKey);
    await prefs.remove(AppConstants.bitbucketPasswordKey);
  }
}
