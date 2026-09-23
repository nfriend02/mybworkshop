#!/usr/bin/env bash
# Github → Netlify: install Flutter, inject env, build web.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_DIR="${HOME}/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --enable-web
flutter --version

mkdir -p assets/config
cat > assets/config/app.env <<EOF
FIREBASE_API_KEY=${FIREBASE_API_KEY:-AIzaSyD8b86X6pY9ktgw4XsJw5kCA58VNcF7tww}
FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN:-mybworkshop-d2b6d.firebaseapp.com}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-mybworkshop-d2b6d}
FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET:-mybworkshop-d2b6d.firebasestorage.app}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID:-941034192072}
FIREBASE_APP_ID=${FIREBASE_APP_ID:-1:941034192072:web:539a2a4407d960eb6639fd}
FIREBASE_MEASUREMENT_ID=${FIREBASE_MEASUREMENT_ID:-G-3RDR3ZLH1C}
APP_TITLE=${APP_TITLE:-My AI Workshop}
APP_DESCRIPTION=${APP_DESCRIPTION:-GIF 편집, 리사이즈, GIF 생성, 문서 압축, QR, 오디오, 요약, 밈, 차트, AI 아바타, 마크다운 발표를 담은 밝고 즐거운 파스텔 AI 워크샵.}
APP_AUTHOR=${APP_AUTHOR:-MyBranch Team}
APP_ICON_URL=${APP_ICON_URL:-/icons/Icon-512.png}
GITHUB_BRANCH_URL=${GITHUB_BRANCH_URL:-https://github.com/nfriend02/mybworkshop}
NETLIFY_SITE_URL=${URL:-${NETLIFY_SITE_URL:-https://mybaiworkshop.netlify.app}}
EOF
cp assets/config/app.env assets/config/app_config.env
cp assets/config/app.env .env

flutter pub get
flutter build web --release
