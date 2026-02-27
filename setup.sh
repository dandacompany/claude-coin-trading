#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# Claude 암호화폐 자동매매 시스템 - 원클릭 설치 스크립트
#
# 사용법:
#   bash <(curl -sL https://trading.dante-labs.com/coin/install.sh)
#
# 또는:
#   curl -sL https://trading.dante-labs.com/coin/install.sh | bash
# ──────────────────────────────────────────────────────────

set -euo pipefail

# ── 색상 정의 ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── 유틸리티 함수 ────────────────────────────────────────
info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $1"; exit 1; }

# ── 헤더 ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   Claude 암호화폐 자동매매 시스템 설치           ║${NC}"
echo -e "${BOLD}${CYAN}║   Powered by Claude Code + Upbit + Telegram     ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ── 필수 도구 확인 ──────────────────────────────────────
info "필수 도구를 확인합니다..."

command -v git >/dev/null 2>&1 || fail "git이 설치되어 있지 않습니다. https://git-scm.com 에서 설치하세요."
command -v python3 >/dev/null 2>&1 || fail "python3이 설치되어 있지 않습니다. https://python.org 에서 설치하세요."
command -v claude >/dev/null 2>&1 || fail "Claude Code CLI가 설치되어 있지 않습니다. npm install -g @anthropic-ai/claude-code"

PYTHON_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYTHON_MAJOR=$(echo "$PYTHON_VER" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VER" | cut -d. -f2)
if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 10 ]); then
  fail "Python 3.10 이상이 필요합니다. (현재: $PYTHON_VER)"
fi

ok "git, python3 ($PYTHON_VER), claude 확인 완료"

# ── 프로젝트 폴더 설정 ──────────────────────────────────
DEFAULT_DIR="claude-coin-trading"
echo ""
echo -ne "${BOLD}프로젝트 폴더명 (기본: ${DEFAULT_DIR}): ${NC}"
read -r PROJECT_DIR
PROJECT_DIR="${PROJECT_DIR:-$DEFAULT_DIR}"

if [ -d "$PROJECT_DIR" ]; then
  warn "'$PROJECT_DIR' 폴더가 이미 존재합니다."
  echo -ne "${BOLD}덮어쓸까요? (y/N): ${NC}"
  read -r OVERWRITE
  if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
    fail "설치를 중단합니다."
  fi
  rm -rf "$PROJECT_DIR"
fi

# ── 저장소 클론 ─────────────────────────────────────────
REPO_URL="https://github.com/dandacompany/claude-coin-trading.git"

info "저장소를 복제합니다..."
git clone --depth 1 "$REPO_URL" "$PROJECT_DIR" 2>/dev/null \
  || fail "저장소 복제에 실패했습니다. URL을 확인하세요: $REPO_URL"
rm -rf "$PROJECT_DIR/.git"  # git 히스토리 제거 (새 프로젝트로 시작)
ok "프로젝트 파일 다운로드 완료"

cd "$PROJECT_DIR"

# ── Python 가상환경 + 의존성 ─────────────────────────────
info "Python 가상환경을 생성합니다..."
python3 -m venv .venv
source .venv/bin/activate
ok "가상환경 생성 완료 (.venv)"

info "Python 패키지를 설치합니다..."
pip install -q -r requirements.txt
ok "패키지 설치 완료 (requests, PyJWT, playwright, python-dotenv)"

# ── Playwright 브라우저 (선택) ───────────────────────────
echo ""
echo -ne "${BOLD}차트 캡처용 Chromium을 설치할까요? (약 150MB) (y/N): ${NC}"
read -r INSTALL_CHROMIUM
if [ "$INSTALL_CHROMIUM" = "y" ] || [ "$INSTALL_CHROMIUM" = "Y" ]; then
  info "Chromium을 설치합니다..."
  playwright install chromium 2>/dev/null && ok "Chromium 설치 완료" || warn "Chromium 설치 실패 (나중에 수동 설치 가능)"
else
  info "Chromium 설치를 건너뜁니다. 나중에 'playwright install chromium'으로 설치하세요."
fi

# ── .env 파일 준비 ──────────────────────────────────────
cp .env.example .env
ok ".env 파일 생성 완료"

# ── 스크립트 실행 권한 ────────────────────────────────────
chmod +x scripts/cron_run.sh scripts/setup_cron.sh scripts/run_analysis.sh 2>/dev/null || true
ok "스크립트 실행 권한 설정 완료"

# ── 런타임 디렉토리 생성 ─────────────────────────────────
mkdir -p data/charts data/snapshots logs/executions logs/claude_responses
ok "데이터/로그 디렉토리 생성 완료"

# ── 완료 ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║   설치 완료!                                     ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}다음 단계:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} API 키를 설정하세요:"
echo -e "     ${BOLD}cd $PROJECT_DIR && code .env${NC}"
echo ""
echo -e "     필요한 키:"
echo -e "     - Upbit API (https://upbit.com/mypage/open_api_management)"
echo -e "     - Tavily API (https://tavily.com)"
echo -e "     - Supabase (https://supabase.com)"
echo -e "     - Telegram Bot (@BotFather)"
echo ""
echo -e "  ${CYAN}2.${NC} Claude Code를 시작하세요:"
echo -e "     ${BOLD}cd $PROJECT_DIR && claude${NC}"
echo ""
echo -e "  ${CYAN}3.${NC} 첫 번째 프롬프트를 입력하세요:"
echo -e "     ${BOLD}\"비트코인 시장을 분석해줘\"${NC}"
echo ""
echo -e "  ${CYAN}4.${NC} 자동매매 cron 등록 (선택):"
echo -e "     ${BOLD}bash scripts/setup_cron.sh install${NC}"
echo ""
echo -e "  CLAUDE.md의 교육 커리큘럼 (Step 0~12)을 따라가세요!"
echo ""
echo -e "  ☕ ${YELLOW}Dante Labs${NC}: https://youtube.com/@dante-labs"
echo ""
