---
name: crypto-trader
description: Claude Code 기반 암호화폐 자동매매 시스템. Upbit 거래소를 통한 매매 실행, 시장 데이터 분석, 공포탐욕지수/뉴스 감성 분석을 종합하여 LLM이 매매 결정을 내리는 지능형 트레이딩 봇. claude -p 를 통한 cron 자동 실행과 대화형 세션을 통한 전략 관리를 모두 지원한다.
version: 2.0.0
author: Dante Labs
tags:
  - 자동매매
  - Upbit
  - 암호화폐
  - Supabase
  - Telegram
---

# crypto-trader 스킬

Claude Code 기반 암호화폐 자동매매 시스템의 메인 오케스트레이션 스킬이다.

## 사용 시점

- 암호화폐 시장을 분석하고 매매 결정을 내릴 때
- 자동매매 cron 실행 시 (`claude -p` 모드)
- 포트폴리오 현황을 확인하거나 과거 의사결정을 리뷰할 때
- 매매 전략을 조회하거나 수정할 때
- 사용자 피드백을 다음 실행에 반영할 때

## 전제 조건

### 필수 API 키 (`.env` 파일)

```bash
UPBIT_ACCESS_KEY=...
UPBIT_SECRET_KEY=...
TAVILY_API_KEY=tvly-...
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
TELEGRAM_BOT_TOKEN=...
TELEGRAM_USER_ID=...

# 안전장치
DRY_RUN=true
MAX_TRADE_AMOUNT=100000
MAX_DAILY_TRADES=3
MAX_POSITION_RATIO=0.5
MIN_TRADE_INTERVAL_HOURS=4
EMERGENCY_STOP=false
```

### 시스템 의존성

```bash
# Python 3.10+
python3 --version

# 필수 패키지 설치
pip install -r requirements.txt

# Playwright 브라우저 (차트 캡처용)
playwright install chromium
```

## 프로젝트 구조

```
claude-coin-trading/
├── CLAUDE.md                      # 프로젝트 지침 + 교육 커리큘럼
├── .env                           # API 키 (git 추적 제외)
├── .env.example                   # API 키 템플릿
├── strategy.md                    # 매매 전략 (LLM이 해석하는 핵심 파일)
├── requirements.txt               # Python 의존성
├── scripts/
│   ├── collect_market_data.py     # Upbit 시장 데이터 + 기술지표 수집
│   ├── collect_fear_greed.py      # 공포탐욕지수 수집
│   ├── collect_news.py            # Tavily 뉴스 수집
│   ├── capture_chart.py           # Playwright 차트 캡처
│   ├── execute_trade.py           # 매매 실행 (안전장치 내장)
│   ├── get_portfolio.py           # 포트폴리오 조회
│   ├── notify_telegram.py         # 텔레그램 알림 전송
│   ├── run_analysis.sh            # 전체 분석 파이프라인 (cron용)
│   ├── cron_run.sh                # cron 실행 래퍼 (로깅, 에러 알림)
│   └── setup_cron.sh              # cron 등록/해제 도우미
├── prompts/
│   └── schemas/
│       └── decision_result.json   # 매매 결정 JSON 스키마
├── data/
│   ├── charts/                    # 캡처된 차트 이미지
│   └── snapshots/                 # 실행 시점 데이터 스냅샷
├── logs/
│   ├── executions/                # 실행 로그
│   └── claude_responses/          # claude -p 원본 응답
└── supabase/
    └── migrations/
        └── 001_initial_schema.sql # DB 스키마
```

## 서브 커맨드

### 1. `analyze` - 시장 분석

전체 데이터를 수집하고 LLM이 시장 분석 리포트를 생성한다.

**실행 흐름:**
1. Upbit API로 시장 데이터 수집 (현재가, OHLCV, 호가, 체결)
2. Fear & Greed Index 수집
3. Tavily로 최신 뉴스 수집
4. (선택) Playwright로 차트 캡처
5. Supabase에서 과거 의사결정 + 미반영 피드백 조회
6. `strategy.md` 읽기
7. 모든 데이터를 종합하여 분석 리포트 생성
8. Supabase에 저장 + 텔레그램 전송

**대화형 프롬프트 예시:**
```
"비트코인 시장 분석해줘"
"현재 시장 상황 어때?"
```

### 2. `execute` - 분석 + 매매 실행

분석 후 전략 조건에 부합하면 매매를 실행한다.

**안전장치:**
- `DRY_RUN=true`면 분석만 수행
- `MAX_TRADE_AMOUNT` 초과 금지
- `MAX_DAILY_TRADES` 체크
- `EMERGENCY_STOP=true`면 즉시 중단

**cron 실행:**
```bash
# cron 등록 도우미 (권장)
bash scripts/setup_cron.sh install    # 대화형 간격 선택
bash scripts/setup_cron.sh status     # 상태 확인
bash scripts/setup_cron.sh remove     # 해제

# cron이 실행하는 래퍼 (직접 호출 불필요)
bash scripts/cron_run.sh
```

### 3. `status` - 포트폴리오 현황

```
"현재 포트폴리오 상태 알려줘"
"잔고 얼마야?"
"최근 매매 내역 보여줘"
```

### 4. `strategy` - 전략 조회/수정

전략은 `strategy.md`에 자연어로 작성. 코드 수정 없이 전략만 바꿀 수 있다.

```
"현재 매매 전략 보여줘"
"RSI 조건을 25로 변경해줘"
"매수 비율을 15%로 올려줘"
```

### 5. `feedback` - 사용자 피드백

```
"다음 실행부터 매수 비율을 5%로 줄여줘"
"당분간 매도만 해줘"
```

## 레퍼런스 스크립트

각 Python 스크립트는 `scripts/` 디렉토리에 레퍼런스 구현이 있다. 스크립트 상세는 각 서브 스킬 문서를 참조:

| 스킬 | 레퍼런스 스크립트 |
|------|-----------------|
| `upbit-api` | `collect_market_data.py`, `execute_trade.py`, `get_portfolio.py` |
| `fear-greed-index` | `collect_fear_greed.py` |
| `tavily-news` | `collect_news.py` |
| `chart-capture` | `capture_chart.py` |
| `trade-notifier` | `notify_telegram.py` |
| (cron 자동화) | `cron_run.sh`, `setup_cron.sh` |

## claude -p 출력 포맷

자동 실행 시 최종 결과를 아래 JSON 형식으로 출력해야 한다.
스키마: `prompts/schemas/decision_result.json`

```json
{
  "timestamp": "ISO 8601",
  "decision": "매수 | 매도 | 관망",
  "confidence": 0.0,
  "reason": "결정 근거 요약",
  "market_analysis": {
    "trend": "상승 | 하락 | 횡보",
    "fear_greed": { "value": 0, "classification": "..." },
    "rsi": 0,
    "sma20_deviation": "-5.2%",
    "news_sentiment": "긍정 | 부정 | 중립",
    "key_factors": ["요인1", "요인2", "요인3"]
  },
  "trade_details": {
    "side": "bid | ask | null",
    "amount": 0,
    "executed": false
  }
}
```

## Supabase 데이터베이스

마이그레이션: `supabase/migrations/001_initial_schema.sql`

| 테이블 | 용도 |
|--------|------|
| `decisions` | 매매 결정 기록 |
| `portfolio_snapshots` | 포트폴리오 스냅샷 |
| `market_data` | 시장 데이터 시계열 |
| `feedback` | 사용자 피드백 |
| `execution_logs` | 실행 로그 |
| `strategy_history` | 전략 변경 이력 |

## 안전장치 (반드시 준수)

| 파라미터 | 기본값 | 설명 |
|---------|--------|------|
| `DRY_RUN` | `true` | 분석만 / 실제 매매 |
| `MAX_TRADE_AMOUNT` | `100000` | 1회 매매 상한 (KRW) |
| `MAX_DAILY_TRADES` | `3` | 일일 매매 상한 |
| `MAX_POSITION_RATIO` | `0.5` | 총 자산 대비 최대 투자 비율 |
| `EMERGENCY_STOP` | `false` | 긴급 매매 중지 |

**규칙:**
- 매매 전 반드시 `EMERGENCY_STOP` + `DRY_RUN` 확인
- `MAX_TRADE_AMOUNT` 초과 주문 금지
- 안전장치 값은 사용자 명시적 요청 없이 변경 금지
