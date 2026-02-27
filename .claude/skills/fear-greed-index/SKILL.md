---
name: fear-greed-index
description: Alternative.me의 Crypto Fear & Greed Index API를 통해 시장 심리 지수를 수집하는 스킬. 현재값, 히스토리, 분류(Extreme Fear ~ Extreme Greed)를 제공한다.
version: 3.0.0
tags:
  - 공포탐욕지수
  - 시장심리
  - API
---

# fear-greed-index 스킬

암호화폐 시장의 심리 지표인 Fear & Greed Index를 수집한다. Alternative.me가 제공하는 무료 공개 API를 사용한다.

공식 문서: https://alternative.me/crypto/fear-and-greed-index/#api

## API 스펙

- **Base URL**: `https://api.alternative.me`
- **엔드포인트**: `GET /fng/`
- **인증**: 불필요 (무료 공개 API)
- **업데이트 주기**: 하루 1회 (UTC 자정)
- **Attribution**: 데이터 표시 시 출처 명시 필요. 상업적 사용 허용 (적절한 출처 표기 하에).

## 요청 파라미터

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `limit` | int | `1` | 반환할 결과 수. `0`이면 전체 히스토리 반환 |
| `format` | str | `json` | 응답 형식: `json` 또는 `csv` (스프레드시트 호환) |
| `date_format` | str | unixtime | 날짜 형식: `us` (MM/DD/YYYY), `cn` 또는 `kr` (YYYY/MM/DD), `world` (DD/MM/YYYY) |

> `time_until_update` 필드는 `limit=1` (최신 값)일 때만 포함된다.

## 요청 예시

```bash
# 현재 지수 (최신 1건)
curl -s "https://api.alternative.me/fng/"

# 최근 7일
curl -s "https://api.alternative.me/fng/?limit=7"

# 한국식 날짜 포맷으로 30일
curl -s "https://api.alternative.me/fng/?limit=30&date_format=kr"

# CSV 형식 (스프레드시트용)
curl -s "https://api.alternative.me/fng/?limit=10&format=csv&date_format=us"

# 전체 히스토리
curl -s "https://api.alternative.me/fng/?limit=0"
```

## 응답 형식

```json
{
  "name": "Fear and Greed Index",
  "data": [
    {
      "value": "25",
      "value_classification": "Extreme Fear",
      "timestamp": "1708905600",
      "time_until_update": "43200"
    }
  ],
  "metadata": {
    "error": null
  }
}
```

### 응답 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `value` | str | 지수 값 (0~100, 문자열 타입) |
| `value_classification` | str | 분류명 (아래 표 참조) |
| `timestamp` | str | Unix timestamp (초 단위) |
| `time_until_update` | str | 다음 업데이트까지 남은 초 (최신 값에만 포함) |

## 지수 분류

| 범위 | 분류 | 트레이딩 의미 |
|------|------|-------------|
| 0-24 | Extreme Fear | 극도의 공포 → 매수 기회 가능 |
| 25-49 | Fear | 공포 |
| 50 | Neutral | 중립 |
| 51-74 | Greed | 탐욕 |
| 75-100 | Extreme Greed | 극도의 탐욕 → 매도 고려 |

## 레퍼런스 스크립트

`scripts/collect_fear_greed.py` — 현재값 + 7일 추이를 수집하여 JSON으로 stdout 출력.

```bash
python3 scripts/collect_fear_greed.py
```

수집 결과 형식:

```json
{
    "timestamp": "ISO 8601",
    "current": {
        "date": "2026-02-26",
        "value": 25,
        "classification": "Extreme Fear"
    },
    "history_7d": [
        {"date": "2026-02-26", "value": 25, "classification": "Extreme Fear"},
        {"date": "2026-02-25", "value": 30, "classification": "Fear"}
    ]
}
```

## 실용 레시피

### 30일 추세 수집

```python
import requests
from datetime import datetime, timezone

r = requests.get("https://api.alternative.me/fng/", params={"limit": 30})
data = r.json()["data"]
for d in data:
    dt = datetime.fromtimestamp(int(d["timestamp"]), tz=timezone.utc)
    print(f"{dt:%Y-%m-%d} | FGI {d['value']:>3} | {d['value_classification']}")
```

### 극단값 감지 (전략 연동)

```python
current = int(data[0]["value"])
if current <= 25:
    signal = "EXTREME_FEAR"   # 매수 기회 탐색
elif current <= 40:
    signal = "FEAR"           # 관망 또는 소규모 매수
elif current >= 75:
    signal = "EXTREME_GREED"  # 매도 고려
elif current >= 60:
    signal = "GREED"          # 관망 또는 익절
else:
    signal = "NEUTRAL"
```

## 전략 연동

- `value <= 30`: 매수 조건 중 하나 (극도의 공포)
- `value >= 75`: 매도 조건 중 하나 (극도의 탐욕)
- 7일 추세 분석: 연속 하락 → 공포 심화, 바닥 반등 → 시장 회복 신호
- 30일 평균 대비 현재값 괴리: 평균보다 20 이상 낮으면 과매도 신호

## 주의 사항

- Bitcoin 중심 심리 지표이며, 알트코인에는 차이가 있을 수 있다.
- 단독 사용 금지 — RSI, 이동평균선, 뉴스 감성과 종합 판단.
- `value`가 문자열 타입으로 반환되므로 `int()` 변환 필요.
- `limit=0` 사용 시 전체 히스토리가 반환되어 응답이 클 수 있음.
