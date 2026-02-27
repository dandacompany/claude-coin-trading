---
name: trade-notifier
description: 텔레그램 Bot API를 사용하여 매매 결과, 분석 리포트, 오류 등의 알림을 전송하는 스킬. MarkdownV2 포맷 지원.
version: 2.0.0
tags:
  - Telegram
  - 알림
  - Bot
---

# trade-notifier 스킬

텔레그램 Bot API를 통해 매매 시스템의 각종 알림을 전송한다.

## 공식 문서

- Telegram Bot API: https://core.telegram.org/bots/api
- sendMessage: https://core.telegram.org/bots/api#sendmessage
- sendPhoto: https://core.telegram.org/bots/api#sendphoto
- MarkdownV2: https://core.telegram.org/bots/api#markdownv2-style

## 환경 변수

```bash
TELEGRAM_BOT_TOKEN=...
TELEGRAM_USER_ID=...
```

## 텔레그램 봇 생성 방법

1. Telegram에서 `@BotFather` 검색
2. `/newbot` 명령으로 봇 생성
3. 봇 이름/유저네임 설정
4. 발급받은 토큰을 `TELEGRAM_BOT_TOKEN`에 설정
5. 봇과 대화를 시작 (시작 버튼 클릭)
6. `https://api.telegram.org/bot{TOKEN}/getUpdates`로 본인 `chat_id` 확인
7. `TELEGRAM_USER_ID`에 설정

## API 호출

```bash
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "'$TELEGRAM_USER_ID'",
    "text": "메시지 내용",
    "parse_mode": "MarkdownV2"
  }'
```

## 레퍼런스 스크립트

`scripts/notify_telegram.py` — 메시지 전송 + 이미지(차트) 전송 지원.

### CLI 사용

```bash
python3 scripts/notify_telegram.py trade "BTC 매수 실행" "10만원 매수, RSI 28"
python3 scripts/notify_telegram.py error "데이터 수집 실패" "Upbit API 타임아웃"
```

## 메시지 타입

| 타입 | 이모지 | 용도 |
|------|--------|------|
| `trade` | 💰 | 매매 실행 알림 |
| `analysis` | 📊 | 분석 리포트 |
| `error` | 🚨 | 오류 발생 |
| `status` | 📋 | 상태 조회 |

## 메시지 예시

### 매매 실행 알림

```
💰 *BTC 매수 실행*

시장가 매수 100,000원
현재가: 145,230,000원
근거: FGI 22(극도의 공포), RSI 28(과매도), SMA20 대비 -6.2%
신뢰도: 0.82

_2026-02-26 14:00:00 KST_
```

## MarkdownV2 이스케이프

다음 문자를 반드시 백슬래시로 이스케이프:

```
_ * [ ] ( ) ~ ` > # + - = | { } . !
```

```python
import re
def escape_md(text: str) -> str:
    return re.sub(r"([_*\[\]()~`>#+\-=|{}.!\\])", r"\\\1", text)
```

## 주의 사항

- 초당 1회 메시지 제한 (개인 채팅).
- MarkdownV2 파싱 오류 시 메시지 미전송. 이스케이프 누락 주의.
- 봇이 사용자에게 메시지를 보내려면 사용자가 먼저 봇에게 `/start` 해야 함.
