class BitbucketCredentials {
  const BitbucketCredentials({
    required this.username,
    required this.password,
  });
  
  final String username;
  final String password;
  
  bool get isValid => username.isNotEmpty && password.isNotEmpty;
  
  Map<String, String> toMap() {
    return {
      'username': username,
      'password': password,
    };
  }
  
  factory BitbucketCredentials.fromMap(Map<String, String> map) {
    return BitbucketCredentials(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
    );
  }
  
  factory BitbucketCredentials.empty() {
    return const BitbucketCredentials(username: '', password: '');
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BitbucketCredentials &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          password == other.password;

  @override
  int get hashCode => username.hashCode ^ password.hashCode;

  @override
  String toString() => 'BitbucketCredentials(username: $username, password: ***)';
}