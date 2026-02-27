#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# 전체 데이터 수집 + 프롬프트 생성 파이프라인
# cron에서 claude -p에 전달할 프롬프트를 stdout으로 출력한다.
#
# 사용법 (cron):
#   bash scripts/run_analysis.sh 2>/dev/null | claude -p --dangerously-skip-permissions
#
# 사용법 (수동 분석):
#   bash scripts/run_analysis.sh
# ──────────────────────────────────────────────────────────

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# .env 로드
if [ -f .env ]; then
  set -a; source .env; set +a
fi

# 긴급 정지 확인
if [ "${EMERGENCY_STOP:-false}" = "true" ]; then
  echo "EMERGENCY_STOP 활성화됨. 실행 중단." >&2
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_DIR="data/snapshots/${TIMESTAMP}"
mkdir -p "$SNAPSHOT_DIR" "logs/executions"

echo "[$(date)] 데이터 수집 시작..." >&2

# 1. 시장 데이터 수집
python3 scripts/collect_market_data.py > "${SNAPSHOT_DIR}/market_data.json" 2>/dev/null \
  || echo '{"error":"market_data 수집 실패"}' > "${SNAPSHOT_DIR}/market_data.json"

# 2. Fear & Greed Index 수집
python3 scripts/collect_fear_greed.py > "${SNAPSHOT_DIR}/fear_greed.json" 2>/dev/null \
  || echo '{"error":"fear_greed 수집 실패"}' > "${SNAPSHOT_DIR}/fear_greed.json"

# 3. 뉴스 수집
python3 scripts/collect_news.py > "${SNAPSHOT_DIR}/news.json" 2>/dev/null \
  || echo '{"error":"news 수집 실패"}' > "${SNAPSHOT_DIR}/news.json"

# 4. 차트 캡처
python3 scripts/capture_chart.py > "${SNAPSHOT_DIR}/chart_paths.json" 2>/dev/null \
  || echo '{"error":"chart 캡처 실패"}' > "${SNAPSHOT_DIR}/chart_paths.json"

# 5. 포트폴리오 조회
python3 scripts/get_portfolio.py > "${SNAPSHOT_DIR}/portfolio.json" 2>/dev/null \
  || echo '{"error":"portfolio 조회 실패"}' > "${SNAPSHOT_DIR}/portfolio.json"

echo "[$(date)] 데이터 수집 완료. 프롬프트 생성 중..." >&2

# 데이터 로드
STRATEGY=$(cat strategy.md)
MARKET_DATA=$(cat "${SNAPSHOT_DIR}/market_data.json")
FEAR_GREED=$(cat "${SNAPSHOT_DIR}/fear_greed.json")
NEWS=$(cat "${SNAPSHOT_DIR}/news.json")
PORTFOLIO=$(cat "${SNAPSHOT_DIR}/portfolio.json")

# Supabase에서 과거 결정 조회 (최근 10건) - PostgREST API 사용
PAST_DECISIONS="[]"
if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  PAST_DECISIONS=$(curl -s \
    "${SUPABASE_URL}/rest/v1/decisions?select=*&order=created_at.desc&limit=10" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    2>/dev/null || echo "[]")
fi

# 미반영 피드백 조회
FEEDBACK="[]"
if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  FEEDBACK=$(curl -s \
    "${SUPABASE_URL}/rest/v1/feedback?select=*&applied=eq.false&order=created_at.desc" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    2>/dev/null || echo "[]")
fi

# 프롬프트를 stdout으로 출력
cat <<PROMPT_EOF
당신은 암호화폐 자동매매 AI 트레이더입니다.
아래 데이터를 종합 분석하고, 전략에 따라 매매 결정을 내려주세요.

═══════════════════════════════════════════
[매매 전략]
═══════════════════════════════════════════
${STRATEGY}

═══════════════════════════════════════════
[시장 데이터 - OHLCV, 기술지표]
═══════════════════════════════════════════
${MARKET_DATA}

═══════════════════════════════════════════
[공포탐욕지수]
═══════════════════════════════════════════
${FEAR_GREED}

═══════════════════════════════════════════
[최신 뉴스 (24시간)]
═══════════════════════════════════════════
${NEWS}

═══════════════════════════════════════════
[현재 포트폴리오]
═══════════════════════════════════════════
${PORTFOLIO}

═══════════════════════════════════════════
[과거 의사결정 (최근 10건)]
═══════════════════════════════════════════
${PAST_DECISIONS}

═══════════════════════════════════════════
[사용자 피드백 (미반영)]
═══════════════════════════════════════════
${FEEDBACK}

═══════════════════════════════════════════
[현재 시각]
═══════════════════════════════════════════
$(date '+%Y-%m-%d %H:%M:%S KST')

═══════════════════════════════════════════
[지시사항]
═══════════════════════════════════════════

1. 위 모든 데이터를 종합하여 시장 상황을 분석하세요.
2. 전략 문서의 매수/매도/관망 조건과 대조하여 결정하세요.
3. 사용자 피드백이 있다면 반드시 반영하세요.
4. 결정을 내린 후, 아래 순서대로 실행하세요:

   a) 결정이 매수 또는 매도인 경우:
      python3 scripts/execute_trade.py [bid|ask] KRW-BTC [금액|수량]

   b) 텔레그램 알림 전송:
      python3 scripts/notify_telegram.py trade "[결정 요약]" "[상세 근거]"

5. 최종 결과를 JSON 형식으로 출력하세요.
PROMPT_EOF
