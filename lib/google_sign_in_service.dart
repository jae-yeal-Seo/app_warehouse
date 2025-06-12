import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // 필요에 따라 scopes를 추가할 수 있습니다
    scopes: ['email', 'profile'],
    clientId:
        '1234567890-abcdefghijklmnop.apps.googleusercontent.com', // 실제 클라이언트 ID로 변경
  );

  // Google Sign-In 프로세스
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Google Sign-In 실행
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        return null;
      }

      // 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw Exception('Google 인증 토큰을 가져올 수 없습니다.');
      }

      // 1. 백엔드에는 idToken만 보냄
      await sendIdTokenToBackend(idToken);

      // 2. accessToken은 필요하면 Google API에 직접 사용
      final userInfo = await getUserInfoFromGoogle(accessToken);

      return {
        'user': googleUser,
        'userInfo': userInfo,
        'idToken': idToken,
        'accessToken': accessToken,
      };
    } catch (error) {
      print('Google Sign-In 오류: $error');
      return null;
    }
  }

  // 백엔드에 idToken 전송
  static Future<void> sendIdTokenToBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-backend.com/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      if (response.statusCode == 200) {
        print('백엔드 로그인 성공: ${response.body}');
      } else {
        print('백엔드 로그인 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('백엔드 통신 오류: $error');
    }
  }

  // Google API에서 사용자 정보 가져오기
  static Future<Map<String, dynamic>?> getUserInfoFromGoogle(
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v1/userinfo?alt=json'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Google API 호출 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Google API 호출 오류: $error');
      return null;
    }
  }

  // 로그아웃
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('로그아웃 완료');
    } catch (error) {
      print('로그아웃 오류: $error');
    }
  }

  // 현재 로그인된 사용자 확인
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return await _googleSignIn.signInSilently();
  }
}
