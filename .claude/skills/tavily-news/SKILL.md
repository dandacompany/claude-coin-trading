---
name: tavily-news
description: Tavily Search API를 사용하여 암호화폐 관련 최신 뉴스를 수집하고 감성 분석 자료로 제공하는 스킬. 한국어/영어 뉴스를 모두 수집하며, LLM이 감성 분석을 수행한다.
version: 3.0.0
tags:
  - Tavily
  - 뉴스
  - 감성분석
  - API
---

# tavily-news 스킬

Tavily Search API를 활용하여 암호화폐 관련 최신 뉴스를 수집한다. 수집된 뉴스의 감성 분석은 LLM이 수행한다.

## 공식 문서

- API 소개: https://docs.tavily.com/documentation/api-reference/introduction
- Search 엔드포인트: https://docs.tavily.com/documentation/api-reference/endpoint/search
- Extract 엔드포인트: https://docs.tavily.com/documentation/api-reference/endpoint/extract

## API 스펙

- **Base URL**: `https://api.tavily.com`
- **인증**: Bearer Token (`Authorization: Bearer tvly-YOUR_API_KEY`)
- **프로젝트 추적**: `X-Project-ID` 헤더로 API 키 하나에 여러 프로젝트 분리 가능

## 환경 변수

```bash
TAVILY_API_KEY=tvly-...
```

## 엔드포인트

### 1. POST /search — 뉴스 검색 (메인)

```bash
curl -X POST "https://api.tavily.com/search" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -d '{
    "query": "Bitcoin BTC cryptocurrency market",
    "search_depth": "basic",
    "topic": "news",
    "time_range": "day",
    "max_results": 10,
    "include_answer": "basic"
  }'
```

#### 요청 파라미터

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `query` | str | *필수* | 검색 쿼리 |
| `search_depth` | str | `basic` | `basic` (1 크레딧), `advanced` (2 크레딧), `fast`, `ultra-fast` |
| `topic` | str | `general` | `general` 또는 `news` |
| `time_range` | str | null | 시간 필터: `day`, `week`, `month`, `year` |
| `start_date` | str | null | 시작일 필터 (YYYY-MM-DD) |
| `end_date` | str | null | 종료일 필터 (YYYY-MM-DD) |
| `max_results` | int | `5` | 최대 결과 수 (0~20) |
| `chunks_per_source` | int | `3` | 소스당 콘텐츠 스니펫 수 (1~3) |
| `include_answer` | bool/str | `false` | AI 요약 답변: `false`, `true`, `basic`, `advanced` |
| `include_raw_content` | bool/str | `false` | 원문 포함: `false`, `true`, `markdown`, `text` |
| `include_images` | bool | `false` | 이미지 검색 수행 |
| `include_image_descriptions` | bool | `false` | 이미지 설명 추가 |
| `include_favicon` | bool | `false` | 파비콘 URL 포함 |
| `include_domains` | array | `[]` | 포함할 도메인 (최대 300개) |
| `exclude_domains` | array | `[]` | 제외할 도메인 (최대 150개) |
| `country` | str | null | 특정 국가 결과 우선 |
| `auto_parameters` | bool | `false` | 검색 파라미터 자동 최적화 |
| `exact_match` | bool | `false` | 인용구 정확 일치 |
| `include_usage` | bool | `false` | 크레딧 사용 정보 포함 |

#### 응답 형식

```json
{
  "query": "Bitcoin BTC cryptocurrency market",
  "answer": "AI 요약 답변 (include_answer 사용 시)",
  "images": [
    {"url": "https://...", "description": "이미지 설명"}
  ],
  "results": [
    {
      "title": "기사 제목",
      "url": "https://...",
      "content": "본문 스니펫",
      "score": 0.95,
      "raw_content": "전체 원문 (include_raw_content 사용 시)",
      "favicon": "https://... (include_favicon 사용 시)"
    }
  ],
  "response_time": 1.23,
  "usage": {"credits": 1},
  "request_id": "uuid"
}
```

### 2. POST /extract — URL 콘텐츠 추출

특정 기사 URL에서 전체 본문을 추출할 때 사용한다.

```bash
curl -X POST "https://api.tavily.com/extract" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -d '{
    "urls": ["https://example.com/article1", "https://example.com/article2"],
    "format": "markdown"
  }'
```

#### 요청 파라미터

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `urls` | str/array | *필수* | 추출할 URL (최대 20개) |
| `query` | str | null | 관련성 기준 재정렬용 쿼리 |
| `chunks_per_source` | int | `3` | 소스당 관련 청크 수 (1~5) |
| `extract_depth` | str | `basic` | `basic` (1 크레딧/5건) 또는 `advanced` (2 크레딧/5건) |
| `format` | str | `markdown` | 출력 형식: `markdown` 또는 `text` |
| `include_images` | bool | `false` | 이미지 URL 추출 |
| `timeout` | float | 10.0/30.0 | 최대 대기 시간 (1.0~60.0초) |

#### 응답 형식

```json
{
  "results": [
    {
      "url": "https://...",
      "raw_content": "추출된 본문",
      "images": ["https://..."],
      "favicon": "https://..."
    }
  ],
  "failed_results": [
    {"url": "https://...", "error": "에러 메시지"}
  ],
  "response_time": 2.5,
  "usage": {"credits": 1}
}
```

## 크레딧 비용

| 기능 | 비용 |
|------|------|
| Search `basic` / `fast` / `ultra-fast` | 1 크레딧/요청 |
| Search `advanced` | 2 크레딧/요청 |
| Extract `basic` | 1 크레딧/5건 |
| Extract `advanced` | 2 크레딧/5건 |

## HTTP 상태 코드

| 코드 | 의미 |
|------|------|
| `200` | 성공 |
| `400` | 잘못된 요청 파라미터 |
| `401` | API 키 누락 또는 유효하지 않음 |
| `429` | Rate limit 초과 |
| `432` | 플랜 한도 초과 |
| `500` | 서버 오류 |

## 검색 쿼리 전략

| 목적 | 쿼리 예시 | 추천 파라미터 |
|------|----------|-------------|
| 일반 시황 | `"Bitcoin BTC cryptocurrency market"` | `topic: "news"`, `time_range: "day"` |
| 규제 뉴스 | `"crypto regulation law SEC"` | `topic: "news"`, `time_range: "week"` |
| 한국 시장 | `"비트코인 암호화폐 시장 한국"` | `topic: "news"`, `country: "KR"` |
| 기관 투자 | `"institutional Bitcoin ETF investment"` | `topic: "news"`, `include_answer: "basic"` |
| 특정 기간 | `"Bitcoin crash"` | `start_date: "2026-02-20"`, `end_date: "2026-02-27"` |

## 레퍼런스 스크립트

`scripts/collect_news.py` — 최근 24시간 BTC 관련 뉴스를 수집하여 JSON으로 stdout 출력.

```bash
python3 scripts/collect_news.py
```

수집 결과 형식:

```json
{
    "timestamp": "ISO 8601",
    "query": "비트코인 Bitcoin BTC 시장",
    "articles_count": 10,
    "articles": [
        {
            "title": "기사 제목",
            "url": "https://...",
            "content": "본문 스니펫 (500자 이내)",
            "published_date": "2026-02-26",
            "score": 0.95
        }
    ]
}
```

## 실용 레시피

### 뉴스 + AI 요약 한 번에 가져오기

```python
import requests, os

r = requests.post("https://api.tavily.com/search",
    headers={"Authorization": f"Bearer {os.environ['TAVILY_API_KEY']}"},
    json={
        "query": "Bitcoin BTC cryptocurrency market news today",
        "topic": "news",
        "time_range": "day",
        "max_results": 10,
        "include_answer": "basic",
        "include_usage": True
    })
data = r.json()
print(f"AI 요약: {data.get('answer', 'N/A')}")
print(f"기사 {len(data['results'])}건, {data['usage']['credits']} 크레딧 사용")
for a in data["results"]:
    print(f"  [{a['score']:.2f}] {a['title']}")
```

### 특정 기사 전문 추출

```python
# Search 결과에서 상위 기사 URL을 추출하여 전문 가져오기
top_urls = [a["url"] for a in data["results"][:3]]
extract = requests.post("https://api.tavily.com/extract",
    headers={"Authorization": f"Bearer {os.environ['TAVILY_API_KEY']}"},
    json={"urls": top_urls, "format": "markdown"})
for result in extract.json()["results"]:
    print(f"\n=== {result['url']} ===")
    print(result["raw_content"][:500])
```

### 한국/글로벌 뉴스 병렬 수집

```python
import concurrent.futures

queries = [
    {"query": "비트코인 암호화폐 시장", "country": "KR"},
    {"query": "Bitcoin BTC crypto market news"},
]
def fetch_news(params):
    base = {"topic": "news", "time_range": "day", "max_results": 5}
    base.update(params)
    return requests.post("https://api.tavily.com/search",
        headers={"Authorization": f"Bearer {os.environ['TAVILY_API_KEY']}"},
        json=base).json()

with concurrent.futures.ThreadPoolExecutor() as executor:
    results = list(executor.map(fetch_news, queries))
# results[0] = 한국 뉴스, results[1] = 글로벌 뉴스
```

## 감성 분류 가이드

LLM이 뉴스를 분석할 때 사용하는 분류:

| 분류 | 해당 뉴스 유형 |
|------|--------------|
| 매우 긍정 | 기관 대규모 매수, ETF 승인, 국가 채택 |
| 긍정 | 가격 상승 전망, 기술 발전, 파트너십 |
| 중립 | 사실 보도, 기술 업데이트, 시장 분석 |
| 부정 | 규제 강화, 해킹, 거래소 문제 |
| 매우 부정 | 전면 금지, 대규모 해킹, 시장 붕괴 |

## 전략 연동

- **매우 부정** 감지 시: 패닉 매도 가능성 → 매수 보류 또는 관망
- **규제 이슈** 발견 시: 매도 우선 고려
- **매우 긍정** 다수 + FGI 탐욕 구간: 고점 경고
- `include_answer`로 AI 요약을 받으면 LLM 분석 비용 절감 가능

## 주의 사항

- `search_depth: "advanced"` 사용 시 크레딧 2배 소모. 자동 실행에서는 `basic` 권장.
- 주말/공휴일 뉴스 부족 시 `time_range: "week"` 또는 날짜 범위 조정.
- **인증 방식 변경**: 최신 API는 Bearer Token 헤더 인증 (`Authorization: Bearer tvly-...`). 구버전 바디 `api_key` 필드도 호환되지만 헤더 방식 권장.
- `429` 에러 시 Rate limit 초과. 재시도 간격을 두고 요청.
- `432` 에러 시 월간 플랜 한도 초과. 플랜 업그레이드 또는 다음 달까지 대기.
