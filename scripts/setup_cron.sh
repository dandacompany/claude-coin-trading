#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# cron 자동매매 등록/해제 도우미
#
# 사용법:
#   bash scripts/setup_cron.sh install    # cron 등록
#   bash scripts/setup_cron.sh remove     # cron 해제
#   bash scripts/setup_cron.sh status     # 등록 상태 확인
# ──────────────────────────────────────────────────────────

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CRON_SCRIPT="${PROJECT_DIR}/scripts/cron_run.sh"
CRON_TAG="# claude-coin-trading"

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

show_status() {
  if crontab -l 2>/dev/null | grep -q "claude-coin-trading"; then
    echo -e "${GREEN}[활성]${NC} cron 자동매매가 등록되어 있습니다."
    echo ""
    crontab -l 2>/dev/null | grep "claude-coin-trading"
  else
    echo -e "${YELLOW}[미등록]${NC} cron 자동매매가 등록되어 있지 않습니다."
  fi
}

install_cron() {
  # 이미 등록되어 있는지 확인
  if crontab -l 2>/dev/null | grep -q "claude-coin-trading"; then
    echo -e "${YELLOW}이미 등록되어 있습니다. 먼저 remove 후 다시 install 하세요.${NC}"
    show_status
    return 1
  fi

  # 실행 간격 선택
  echo -e "${BOLD}자동 실행 간격을 선택하세요:${NC}"
  echo ""
  echo "  1) 4시간  (0, 4, 8, 12, 16, 20시)"
  echo "  2) 8시간  (0, 8, 16시) [권장]"
  echo "  3) 12시간 (0, 12시)"
  echo "  4) 24시간 (매일 9시)"
  echo ""
  echo -ne "${BOLD}선택 (1-4, 기본: 2): ${NC}"
  read -r CHOICE
  CHOICE="${CHOICE:-2}"

  case "$CHOICE" in
    1) SCHEDULE="0 0,4,8,12,16,20 * * *" ; DESC="4시간 간격" ;;
    2) SCHEDULE="0 0,8,16 * * *"          ; DESC="8시간 간격" ;;
    3) SCHEDULE="0 0,12 * * *"            ; DESC="12시간 간격" ;;
    4) SCHEDULE="0 0 * * *"               ; DESC="24시간 (매일 자정)" ;;
    *) echo -e "${RED}잘못된 선택입니다.${NC}"; return 1 ;;
  esac

  # cron 등록
  CRON_LINE="${SCHEDULE} ${CRON_SCRIPT} ${CRON_TAG}"
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -

  echo ""
  echo -e "${GREEN}cron 등록 완료!${NC}"
  echo -e "  간격: ${BOLD}${DESC}${NC}"
  echo -e "  스크립트: ${CRON_SCRIPT}"
  echo ""
  echo -e "${YELLOW}주의: DRY_RUN=true 상태에서 충분히 테스트한 후 실전 전환하세요.${NC}"
}

remove_cron() {
  if ! crontab -l 2>/dev/null | grep -q "claude-coin-trading"; then
    echo -e "${YELLOW}등록된 cron이 없습니다.${NC}"
    return 0
  fi

  crontab -l 2>/dev/null | grep -v "claude-coin-trading" | crontab -
  echo -e "${GREEN}cron 자동매매가 해제되었습니다.${NC}"
}

# CLI
case "${1:-status}" in
  install) install_cron ;;
  remove)  remove_cron ;;
  status)  show_status ;;
  *)
    echo "사용법: bash scripts/setup_cron.sh [install|remove|status]"
    exit 1
    ;;
esac
