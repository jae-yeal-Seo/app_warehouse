// 환경별 백엔드 URL 설정
const bool kIsProduction = bool.fromEnvironment(
  'PRODUCTION',
  defaultValue: false,
);

const String kBackendBaseUrl =
    kIsProduction
        ? 'https://your-production-domain.com' // 프로덕션 URL (나중에 실제 도메인으로 변경)
        : 'http://192.168.192.161:8000'; // 로컬 개발 환경 (현재 Wi-Fi IP)
