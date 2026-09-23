# My AI Workshop (나의 AI 워크샵)

MyBranch 포트폴리오 브랜치앱. Flutter 웹/모바일, Firebase Firestore, Github → Netlify.

- Github: https://github.com/nfriend02/mybworkshop
- Netlify: https://mybworkshop.netlify.app

## 구조

Feature-Sliced Design. 자세한 트리는 `lib/STRUCTURE.md`.

| 레이어 | 역할 |
|--------|------|
| `lib/main.dart` | 진입점. dotenv 후 Firebase 초기화 |
| `lib/app/` | 라우터, 테마, Firebase 부트스트랩 |
| `lib/pages/` | Home, Upload, 도구 화면 |
| `lib/features/` | GIF, 리사이즈, 압축, 요약 등 도메인 |
| `lib/entities/` | 작업·업로드 모델 |
| `lib/services/` | Firestore CRUD, Auth |
| `lib/shared/` | 레이아웃, 위젯, `/api` 클라이언트 |

## 반응형

- 데스크톱 769px 이상: 왼쪽 사이드바 + 오른쪽 콘텐츠
- 모바일 768px 이하: 상단 가로 메뉴 + 아래 콘텐츠
- 목록은 스크롤 끝에서 10개씩 더 보여 줍니다

## 로컬 실행

```bash
cp .env.example .env
flutter pub get
flutter run -d chrome
```

Firebase 초기화에 실패하면 데모 모드로 UI만 열립니다. 기본 클라이언트 설정은 `lib/firebase_options.dart`와 `assets/config/app.env`에 있습니다.

## Firebase

- 프로젝트: `mybworkshop`
- 리전: `asia-northeast3`
- 컬렉션: `jobs`, `uploads` (`createdAt`, `status`)
- 인덱스: `firestore.indexes.json`
- 규칙: `firestore.rules`
- CRUD: `lib/services/firestore_service.dart` (`addData`, `getData`, `updateData`, `deleteData`)

## Github → Netlify

1. 이 저장소를 Netlify에 연결하고 프로덕션 브랜치를 `main`으로 둡니다.
2. 빌드는 `netlify.toml` → `netlify/build.sh`.
3. Environment variables에 `.env.example`과 같은 키를 넣습니다. 비어 있으면 저장소의 공개 웹 설정을 사용합니다.
4. `main`에 PR이 병합되면 Netlify가 웹을 다시 빌드합니다.
5. `/api/health`, `/api/summarize`는 Netlify Functions입니다.

### 업로드 체크리스트

- [x] Github branch URL: https://github.com/nfriend02/mybworkshop
- [x] 아이콘: `web/icons/Icon-512.png` (`/icons/Icon-512.png`)
- [x] 설명 200자 이내 (`APP_DESCRIPTION`)
- [x] 제작자/팀명: MyBranch Team

## PR

기능 브랜치에서 작업한 뒤 `main`으로 PR을 보냅니다. 병합되면 Netlify가 자동으로 빌드합니다.
