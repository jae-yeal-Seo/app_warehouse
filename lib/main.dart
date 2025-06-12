import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_sign_in_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anywhere Anytime Japanese',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleSignInAccount? _currentUser;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  // 현재 로그인된 사용자 확인
  Future<void> _checkCurrentUser() async {
    final user = await GoogleSignInService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  // Google Sign-In 실행
  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    final result = await GoogleSignInService.signInWithGoogle();
    setState(() {
      _isLoading = false;
      if (result != null) {
        _currentUser = result['user'];
        _userInfo = result['userInfo'];

        // 테스트용: user가 null이면 더미 사용자 생성
        if (_currentUser == null && _userInfo != null) {
          // 더미 사용자로 UI 테스트
          print('더미 사용자로 로그인 처리');
        }
      }
    });

    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google 로그인 성공!')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google 로그인 실패 또는 취소')));
    }
  }

  // 로그아웃 실행
  Future<void> _handleSignOut() async {
    await GoogleSignInService.signOut();
    setState(() {
      _currentUser = null;
      _userInfo = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('로그아웃 완료')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anywhere Anytime Japanese'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentUser == null && _userInfo == null) ...[
                const Icon(Icons.person_outline, size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                const Text(
                  '로그인이 필요합니다',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                      onPressed: _handleSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Google로 로그인'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
              ] else ...[
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      (_currentUser?.photoUrl != null)
                          ? NetworkImage(_currentUser!.photoUrl!)
                          : null,
                  child: const Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  '안녕하세요, ${_currentUser?.displayName ?? _userInfo?['name'] ?? '사용자'}님!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser?.email ??
                      _userInfo?['email'] ??
                      'test@example.com',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (_userInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google API 사용자 정보:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('ID: ${_userInfo!['id']}'),
                        Text('이름: ${_userInfo!['name']}'),
                        Text('이메일: ${_userInfo!['email']}'),
                        if (_userInfo!['locale'] != null)
                          Text('지역: ${_userInfo!['locale']}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                ElevatedButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('로그아웃'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
