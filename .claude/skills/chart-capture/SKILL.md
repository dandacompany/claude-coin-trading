---
name: chart-capture
description: Playwright를 사용하여 암호화폐 차트(Upbit)를 캡처하는 스킬. headless 모드로 서버 환경에서 실행 가능하다.
version: 2.0.0
tags:
  - Playwright
  - 차트
  - 스크린샷
---

# chart-capture 스킬

Playwright를 사용하여 암호화폐 차트를 자동으로 캡처한다. 캡처된 이미지는 Claude의 멀티모달 분석(시각적 패턴 인식)에 활용된다.

## 공식 문서

- Playwright Python: https://playwright.dev/python/docs/intro
- Upbit 차트: `https://upbit.com/full_chart?code=CRIX.UPBIT.KRW-BTC`

## 의존성

```bash
pip install playwright
playwright install chromium
```

## 캡처 대상

| 소스 | URL |
|------|-----|
| Upbit 차트 | `https://upbit.com/full_chart?code=CRIX.UPBIT.KRW-BTC` |
| TradingView | `https://www.tradingview.com/chart/?symbol=UPBIT:BTCKRW` |

## 캡처 설정

```python
browser = await p.chromium.launch(headless=True)
context = await browser.new_context(
    viewport={"width": 1920, "height": 1080},
    locale="ko-KR",
    timezone_id="Asia/Seoul",
)
```

| 설정 | 값 | 이유 |
|------|-----|------|
| `headless` | `True` | 서버(GUI 없는 환경) 실행 |
| `viewport` | 1920x1080 | 차트가 잘리지 않는 넓은 해상도 |
| `locale` | `ko-KR` | 한국어 인터페이스 |
| `timezone_id` | `Asia/Seoul` | 한국 시간 기준 |

## 차트 렌더링 대기

차트는 JavaScript 동적 렌더링이므로 충분한 대기 필요:

```python
await page.goto(url, wait_until="networkidle", timeout=30000)
await page.wait_for_timeout(5000)  # 차트 애니메이션 완료 대기
```

## 레퍼런스 스크립트

`scripts/capture_chart.py` — Upbit BTC/KRW 차트를 캡처하여 `data/charts/`에 저장.

출력 형식:

```json
{
  "timestamp": "ISO 8601",
  "chart_path": "data/charts/btc_chart_20260226_140000.png"
}
```

## 서버 환경 (Linux)

```bash
# Playwright 시스템 의존성 자동 설치
playwright install-deps chromium
```

## 트러블슈팅

| 증상 | 해결 |
|------|------|
| 빈 스크린샷 | `wait_for_timeout` 값을 8000~10000으로 증가 |
| 타임아웃 오류 | `timeout`을 60000으로 증가 |
| Chromium 실행 실패 | `playwright install-deps` 실행 |
