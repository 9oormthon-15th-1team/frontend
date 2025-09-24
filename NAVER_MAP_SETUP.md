# 네이버 맵 API 설정 가이드

## 🗝️ API 키 발급

1. [네이버 클라우드 플랫폼](https://console.ncloud.com) 접속
2. **AI·NAVER API** > **Maps** > **Web Dynamic Map** 서비스 신청
3. **Application 등록** > **Mobile Dynamic Map** 추가
4. **Client ID** 발급 완료

## 📱 Flutter 앱 설정

### 1. API 키 설정
`lib/core/constants/api_keys.dart` 파일에서 API 키를 설정하세요:

```dart
static const String naverMapClientId = 'YOUR_ACTUAL_CLIENT_ID_HERE';
```

### 2. Android 설정

`android/app/src/main/AndroidManifest.xml` 파일에 다음을 추가:

```xml
<application>
    <!-- 네이버 맵 API 키 -->
    <meta-data
        android:name="com.ncloud.maps.map.CLIENT_ID"
        android:value="YOUR_NAVER_CLIENT_ID" />

    <!-- 기존 application 내용 -->
</application>
```

### 3. iOS 설정

`ios/Runner/Info.plist` 파일에 다음을 추가:

```xml
<dict>
    <!-- 네이버 맵 API 키 -->
    <key>NMFClientId</key>
    <string>YOUR_NAVER_CLIENT_ID</string>

    <!-- 기존 plist 내용 -->
</dict>
```

### 4. 권한 설정

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>이 앱은 지도 서비스를 위해 위치 정보를 사용합니다.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>이 앱은 지도 서비스를 위해 위치 정보를 사용합니다.</string>
```

## 🚀 실행 방법

1. 위의 설정을 모두 완료
2. `flutter clean && flutter pub get`
3. `flutter run`

## 🎯 기본 기능

### 맵 화면
- ✅ 네이버 맵 표시
- ✅ 줌 인/아웃 버튼
- ✅ 마커 추가/제거
- ✅ 현재 위치 표시

### 빠른 이동
- 🏢 **서울시청**: 서울특별시 중구 세종대로 110
- 🚇 **강남역**: 서울특별시 강남구 강남대로 지하 396
- 🎭 **홍대입구역**: 서울특별시 마포구 양화로 지하 188

### 맵 컨트롤
- **탭**: 좌표 로그 출력
- **줌**: +/- 버튼으로 확대/축소
- **마커**: 현재 위치에 마커 추가
- **초기화**: 모든 마커 제거

## 🔧 문제 해결

### "API 키가 유효하지 않습니다"
- `api_keys.dart`에 올바른 Client ID 설정 확인
- Android/iOS 네이티브 설정 확인

### "맵이 로드되지 않습니다"
- 인터넷 연결 확인
- 권한 설정 확인
- 네이버 클라우드 플랫폼에서 서비스 활성화 상태 확인

### 위치 권한 오류
- iOS: Info.plist에 위치 권한 설명 추가
- Android: AndroidManifest.xml에 위치 권한 추가

## 📚 참고 문서

- [네이버 맵 Flutter 플러그인](https://pub.dev/packages/flutter_naver_map)
- [네이버 클라우드 플랫폼 Maps API](https://guide.ncloud-docs.com/docs/naveropenapiv3-maps-overview)
- [Flutter 위치 서비스](https://pub.dev/packages/geolocator)

---

**주의**: API 키는 절대 Git에 커밋하지 마세요! `.gitignore`에 이미 관련 패턴이 추가되어 있습니다.