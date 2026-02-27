#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# cron 실행 래퍼
#
# run_analysis.sh를 실행하고, claude -p에 파이프한 뒤,
# 결과를 로그에 저장하고, 에러 시 텔레그램으로 알린다.
#
# crontab 등록:
#   0 0,8,16 * * * /path/to/claude-coin-trading/scripts/cron_run.sh
# ──────────────────────────────────────────────────────────

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# .env 로드
if [ -f .env ]; then
  set -a; source .env; set +a
fi

# Python 가상환경 활성화
if [ -f .venv/bin/activate ]; then
  source .venv/bin/activate
fi

# 긴급 정지 확인
if [ "${EMERGENCY_STOP:-false}" = "true" ]; then
  echo "[$(date)] EMERGENCY_STOP 활성화됨. 실행 중단." >&2
  exit 0
fi

# 로그 디렉토리 생성
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="logs/executions"
RESPONSE_DIR="logs/claude_responses"
mkdir -p "$LOG_DIR" "$RESPONSE_DIR"

LOG_FILE="${LOG_DIR}/${TIMESTAMP}.log"
RESPONSE_FILE="${RESPONSE_DIR}/${TIMESTAMP}.txt"

echo "[$(date)] === cron 실행 시작 ===" > "$LOG_FILE"

# 에러 발생 시 텔레그램 알림
notify_error() {
  local msg="$1"
  echo "[$(date)] ERROR: ${msg}" >> "$LOG_FILE"
  python3 scripts/notify_telegram.py error "cron 실행 오류" "$msg" 2>/dev/null || true
}

# 1. 데이터 수집 + 프롬프트 생성
echo "[$(date)] 데이터 수집 중..." >> "$LOG_FILE"
PROMPT=$(bash scripts/run_analysis.sh 2>>"$LOG_FILE")

if [ -z "$PROMPT" ]; then
  notify_error "프롬프트 생성 실패 - 데이터 수집 단계에서 오류 발생"
  exit 1
fi

echo "[$(date)] 프롬프트 생성 완료 ($(echo "$PROMPT" | wc -c) bytes)" >> "$LOG_FILE"

# 2. claude -p 실행
echo "[$(date)] claude -p 분석 시작..." >> "$LOG_FILE"
RESPONSE=$(echo "$PROMPT" | claude -p --dangerously-skip-permissions --allowedTools "Bash(python3:*)" 2>>"$LOG_FILE") || {
  notify_error "claude -p 실행 실패"
  exit 1
}

# 3. 응답 저장
echo "$RESPONSE" > "$RESPONSE_FILE"
echo "[$(date)] claude 응답 저장: ${RESPONSE_FILE}" >> "$LOG_FILE"

# 4. 완료
echo "[$(date)] === cron 실행 완료 ===" >> "$LOG_FILE"
