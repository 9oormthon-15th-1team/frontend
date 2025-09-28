# Porthole in Jeju - Frontend

제주도 포트홀 신고 모바일 애플리케이션

## 서비스 개요

시민이 도로의 포트홀을 발견했을 때 위치 정보와 사진을 통해 간편하게 신고할 수 있는 Flutter 기반 모바일 앱입니다.

### 핵심 기능

- **지도 기반 신고**: 네이버 지도 API를 통한 정확한 위치 지정 및 포트홀 현황 시각화
- **사진 신고**: 카메라/갤러리 연동으로 다중 이미지 업로드
- **신고 관리**: 실시간 신고 목록 조회 및 처리 상태 추적
- **위치 서비스**: GPS 기반 자동 위치 인식 및 주소 변환

## 기술 스택

### 프레임워크
- **Flutter** `^3.9.0` - 크로스 플랫폼 모바일 개발
- **Dart** `^3.9.0`

### 주요 의존성
```yaml
dependencies:
  # 지도 & 위치
  flutter_naver_map: ^1.2.4    # 네이버 지도 SDK
  geolocator: ^14.0.2          # GPS 위치 서비스
  geocoding: ^4.0.0            # 좌표-주소 변환
  permission_handler: ^11.0.1   # 권한 관리

  # 네트워킹
  http: ^1.2.2                 # HTTP 클라이언트
  flutter_dotenv: ^5.1.0       # 환경변수

  # UI/UX
  flutter_svg: ^2.0.7          # SVG 지원
  lottie: ^3.1.2               # 애니메이션
  go_router: ^14.6.2           # 라우팅

  # 디바이스
  image_picker: ^1.0.4         # 카메라/갤러리
  shared_preferences: ^2.2.2   # 로컬 저장소
```

## 프로젝트 구조

```
lib/
├── core/                       # 공통 기능
│   ├── constants/              # API 키, 앱 설정
│   ├── models/                 # 데이터 모델 (Pothole, PotholeReport, PotholeStatus)
│   ├── router/                 # GoRouter 설정
│   ├── services/               # API, 로깅, 디버그
│   ├── theme/                  # 디자인 시스템
│   └── widgets/                # 공통 위젯
├── features/                   # 기능별 모듈
│   ├── splash/                 # 스플래시
│   ├── onboarding/             # 온보딩
│   ├── home/                   # 홈 (지도)
│   ├── pothole_report/         # 신고
│   ├── pothole_detail/         # 신고 상세
│   ├── potholes/               # 목록
│   └── settings/               # 설정
└── main.dart
```

**아키텍처**: Feature-First + Clean Architecture

## 개발 환경 설정

### 필수 요구사항
- Flutter SDK `>=3.9.0`
- Android Studio / VS Code
- 네이버 클라우드 플랫폼 Maps API 키

### 설치 및 실행

```bash
# 1. 클론
git clone [repository-url]
cd porthole_goorm/frontend

# 2. 의존성 설치
flutter pub get

# 3. 환경변수 설정 (.env 파일 생성)
NAVER_MAP_CLIENT_ID=your_client_id
API_BASE_URL=your_api_url

# 4. 실행
flutter run
```

## 주요 구현 내용

### 지도 기반 신고 시스템
- 네이버 지도 API 연동을 통한 실시간 위치 서비스
- GPS 기반 자동 위치 인식 및 수동 위치 지정
- 포트홀 신고 현황 마커 시각화 (상태별 색상 구분)

### 이미지 처리
- 카메라/갤러리 연동 다중 이미지 업로드
- 이미지 메타데이터 자동 수집 (위치, 시간)

### 신고 관리
- 실시간 신고 목록 조회 및 상태 추적
- 신고 상세 정보 확인 및 처리 현황 업데이트
