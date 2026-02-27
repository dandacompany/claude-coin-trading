# Claude 암호화폐 자동매매 시스템

## 프로젝트 개요

Claude Code 기반 암호화폐 자동매매 봇. `claude -p` 비대화형 모드로 cron 자동 실행하고, Claude 대화형 세션으로 전략 관리 및 피드백을 수행한다.

**핵심 설계 철학:** 매매 로직을 코드로 하드코딩하지 않는다. `strategy.md`에 자연어로 전략을 정의하고, Claude가 데이터를 해석하여 자율적으로 판단한다. Python 스크립트는 데이터 수집과 API 호출만 담당한다.

## 교육 커리큘럼

이 프로젝트는 빈 폴더에서 시작하여, Claude Code에 프롬프트를 하나씩 입력하면서 자동매매 시스템을 직접 구축하는 교육용 프로젝트이다. 아래 순서대로 진행한다.

### Step 0: 환경 준비

```
"프로젝트 환경을 세팅해줘. Python 가상환경을 만들고, requirements.txt로 의존성을 설치하고, .env.example을 복사해서 .env 파일을 준비해줘."
```

### Step 1: 시장 데이터 수집

```
"Upbit API로 BTC/KRW 시장 데이터를 수집하는 Python 스크립트를 만들어줘.
현재가, 일봉 30일, 4시간봉 42개, 호가, 최근 체결을 수집하고,
RSI(14), SMA(20), MACD, 볼린저밴드를 계산해서 JSON으로 출력해줘."
```

### Step 2: 공포탐욕지수 수집

```
"Alternative.me API로 Crypto Fear & Greed Index를 수집하는 스크립트를 만들어줘.
현재값과 최근 7일 추이를 JSON으로 출력해줘."
```

### Step 3: 뉴스 수집

```
"Tavily Search API로 최근 24시간 BTC 관련 뉴스를 수집하는 스크립트를 만들어줘.
한국어/영어 뉴스를 모두 수집하고, 감성 분석은 나중에 LLM이 수행할 거야."
```

### Step 4: 차트 캡처

```
"Playwright로 Upbit BTC/KRW 차트를 스크린샷으로 캡처하는 Python 스크립트를 만들어줘.
headless 모드로 실행하고, data/charts/ 에 저장해줘."
```

### Step 5: 포트폴리오 조회

```
"Upbit API로 내 계좌 잔고를 조회하는 스크립트를 만들어줘.
KRW 잔고, 보유 코인별 수량/평균매수가/현재가/수익률을 계산해서 JSON으로 출력해줘."
```

### Step 6: 매매 전략 정의

```
"strategy.md 파일을 만들어줘. 보수적인 BTC 매매 전략을 자연어로 작성해줘.
매수 조건(FGI, RSI, SMA 기반), 매도 조건(수익률/손절/과매수), 관망 조건을 포함해줘."
```

### Step 7: 매매 실행 스크립트

```
"Upbit API로 시장가 매수/매도를 실행하는 Python 스크립트를 만들어줘.
반드시 DRY_RUN, EMERGENCY_STOP, MAX_TRADE_AMOUNT 안전장치를 내장해줘."
```

### Step 8: 텔레그램 알림

```
"텔레그램 Bot API로 매매 결과, 분석 리포트, 오류를 알림하는 스크립트를 만들어줘.
MarkdownV2 포맷으로 전송하고, 이미지(차트) 전송도 지원해줘."
```

### Step 9: Supabase 데이터베이스

```
"매매 기록을 저장할 Supabase 데이터베이스를 설계해줘.
decisions, portfolio_snapshots, market_data, feedback, execution_logs, strategy_history 테이블이 필요해."
```

### Step 10: 분석 파이프라인

```
"위에서 만든 스크립트들을 순서대로 실행하고, 수집된 데이터와 전략을 조합하여
claude -p에 전달할 프롬프트를 생성하는 셸 스크립트를 만들어줘."
```

### Step 11: 시장 분석 실행

```
"비트코인 시장을 분석해줘. 시장 데이터, 공포탐욕지수, 뉴스를 수집하고
전략에 따라 매수/매도/관망 결정을 내려줘."
```

### Step 12: cron 자동화

```
"자동매매를 cron으로 정기 실행하도록 설정해줘.
setup_cron.sh로 8시간 간격을 등록하고, DRY_RUN=true 상태로 먼저 테스트하고 싶어."
```

## 프로젝트 구조

```
claude-coin-trading/
├── CLAUDE.md                      # 이 파일 (프로젝트 지침)
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

## 실행 모드

### 1. 자동 실행 (cron)

```bash
# cron 등록 도우미 사용 (권장)
bash scripts/setup_cron.sh install    # 대화형으로 간격 선택 (4h/8h/12h/24h)
bash scripts/setup_cron.sh status     # 등록 상태 확인
bash scripts/setup_cron.sh remove     # cron 해제
```

파이프라인: `cron_run.sh` → .env 로드 → 긴급정지 확인 → `run_analysis.sh` (데이터 수집 + 프롬프트 조립) → `claude -p` 분석/실행 → DB 저장 → 텔레그램 알림

**cron_run.sh 기능:**
- `.venv` Python 가상환경 자동 활성화
- `EMERGENCY_STOP` 긴급 정지 체크
- 실행 로그 자동 저장 (`logs/executions/`)
- Claude 응답 원본 저장 (`logs/claude_responses/`)
- 에러 발생 시 텔레그램 알림

### 2. 대화형 (Claude 세션)

```bash
cd ~/path/to/claude-coin-trading && claude
```

가능한 작업: 전략 수정, 피드백 제출, 포트폴리오 조회, 성과 분석, 긴급 정지, 수동 실행

## 핵심 파일

### strategy.md (전략 파일)

- LLM이 프롬프트로 읽어 해석하는 **매매 전략 문서**
- 자연어로 작성하며, 코드로 하드코딩하지 않는다
- 변경 시 `strategy_history` 테이블에 버전 기록

### .env (환경변수)

- 모든 API 키와 안전장치 파라미터를 관리
- `DRY_RUN=true`가 기본값 (실제 매매 미실행)
- `EMERGENCY_STOP=true` 설정 시 모든 매매 즉시 중지

## 안전장치 (반드시 준수)

| 파라미터 | 기본값 | 설명 |
|---------|--------|------|
| `DRY_RUN` | `true` | true: 분석만, false: 실제 매매 |
| `MAX_TRADE_AMOUNT` | `100000` | 1회 매매 금액 상한 (KRW) |
| `MAX_DAILY_TRADES` | `3` | 일일 매매 횟수 상한 |
| `MAX_POSITION_RATIO` | `0.5` | 총 자산 대비 최대 투자 비율 |
| `MIN_TRADE_INTERVAL_HOURS` | `4` | 최소 매매 간격 (시간) |
| `EMERGENCY_STOP` | `false` | true: 모든 매매 즉시 중지 |

**규칙:**
- 매매 실행 전 반드시 `EMERGENCY_STOP` 확인
- 매매 실행 전 반드시 `DRY_RUN` 확인
- `MAX_TRADE_AMOUNT` 초과 주문 금지
- 안전장치 값은 사용자 명시적 요청 없이 변경 금지

## 데이터베이스 (Supabase PostgreSQL)

| 테이블 | 용도 |
|--------|------|
| `decisions` | 매매 결정 기록 (decision, reason, confidence, 지표 스냅샷, 체결 결과) |
| `portfolio_snapshots` | 포트폴리오 스냅샷 (잔고, 평가액, 수익률) |
| `market_data` | 시장 데이터 (가격, 거래량, RSI, SMA, FGI, 뉴스 감성) |
| `feedback` | 사용자 피드백 (type, content, applied 여부) |
| `execution_logs` | 실행 로그 (mode, duration, errors) |
| `strategy_history` | 전략 변경 이력 (version, content, change_summary) |

## 텔레그램 알림

모든 자동 실행 결과는 텔레그램으로 보고한다:

- **매매 실행 시**: 결정(매수/매도/관망), 금액, 근거 요약, 포트폴리오 변동
- **에러 발생 시**: 에러 Phase, 에러 메시지, 영향 범위
- **일일 요약**: 당일 거래 횟수, 수익률, 포트폴리오 현황

## 스킬 구성

| 스킬 | 위치 | 용도 |
|------|------|------|
| `crypto-trader` | `.claude/skills/crypto-trader/` | 메인 스킬 - 분석, 매매, 상태, 전략, 피드백 |
| `upbit-api` | `.claude/skills/upbit-api/` | Upbit REST API 래퍼 |
| `fear-greed-index` | `.claude/skills/fear-greed-index/` | Fear & Greed Index 수집 |
| `tavily-news` | `.claude/skills/tavily-news/` | Tavily 뉴스 검색 + 감성 분석 |
| `chart-capture` | `.claude/skills/chart-capture/` | Playwright 차트 스크린샷 |
| `trade-notifier` | `.claude/skills/trade-notifier/` | Telegram Bot 알림 |

### 스킬-파이프라인 연동

각 파이프라인 단계는 대응하는 스킬 문서를 참조하여 실행한다. 스킬에는 API 스펙, 요청/응답 형식, 에러 처리, 실용 레시피가 포함되어 있다.

| 파이프라인 단계 | 참조 스킬 | 실행 스크립트 | 공식 API 문서 |
|---------------|----------|-------------|-------------|
| 시장 데이터 수집 | `upbit-api` | `collect_market_data.py` | https://docs.upbit.com |
| 공포탐욕지수 수집 | `fear-greed-index` | `collect_fear_greed.py` | https://alternative.me/crypto/fear-and-greed-index/#api |
| 뉴스 수집 | `tavily-news` | `collect_news.py` | https://docs.tavily.com |
| 차트 캡처 | `chart-capture` | `capture_chart.py` | — |
| 포트폴리오 조회 | `upbit-api` | `get_portfolio.py` | https://docs.upbit.com |
| 매매 실행 | `upbit-api` | `execute_trade.py` | https://docs.upbit.com |
| 텔레그램 알림 | `trade-notifier` | `notify_telegram.py` | https://core.telegram.org/bots/api |

**스킬 사용 원칙:**
- 스크립트를 생성하거나 수정할 때 반드시 해당 스킬의 API 스펙과 레시피를 참조한다.
- API 엔드포인트, 파라미터, 인증 방식은 스킬 문서에 정의된 내용을 따른다.
- 스크립트에서 에러가 발생하면 스킬의 트러블슈팅 섹션을 먼저 확인한다.

## 데이터 소스

| 소스 | API | 용도 | 인증 |
|------|-----|------|------|
| Upbit | `api.upbit.com/v1` | 시세, 호가, 캔들, 매매 실행 | JWT (Access + Secret Key) |
| Alternative.me | `api.alternative.me/fng/` | 공포/탐욕 지수 | 없음 (무료) |
| Tavily | `api.tavily.com/search` | 뉴스 검색 + AI 요약 | API Key |
| Playwright | headless Chromium | 차트 스크린샷 캡처 | 없음 |
| Supabase | PostgreSQL (PostgREST) | 데이터 저장/조회 | Service Role Key |
| Telegram | `api.telegram.org/bot` | 실행 보고 알림 | Bot Token |

## 주의사항

- 이 시스템은 **실제 자산을 거래**할 수 있습니다. 반드시 `DRY_RUN=true`로 충분히 테스트 후 실전 전환하세요.
- `strategy.md` 수정 시 항상 `strategy_history` 테이블에 변경 기록을 남기세요.
- 피드백은 `feedback` 테이블에 저장하고, 다음 자동 실행 시 프롬프트에 주입됩니다.
- cron 자동 실행 시 `--dangerously-skip-permissions` 플래그를 사용하므로, 스크립트 보안에 유의하세요.
