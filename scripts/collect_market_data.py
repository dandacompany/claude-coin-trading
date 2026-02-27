#!/usr/bin/env python3
"""
Upbit 시장 데이터 수집 스크립트

수집 항목:
  - 현재가 (ticker)
  - 일봉 캔들 30일 / 4시간봉 캔들 42개
  - 호가창 (orderbook)
  - 최근 체결 100건
  - 기술적 지표: SMA(20), EMA(10), RSI(14), MACD, 볼린저밴드, 스토캐스틱

출력: JSON (stdout)
"""

import hashlib
import json
import os
import sys
import time
import uuid

import jwt
import requests

UPBIT_API = "https://api.upbit.com/v1"


# ── Upbit JWT 인증 ──────────────────────────────────────
def make_auth_header(query_string: str | None = None) -> dict:
    payload = {
        "access_key": os.environ["UPBIT_ACCESS_KEY"],
        "nonce": str(uuid.uuid4()),
        "timestamp": int(time.time() * 1000),
    }
    if query_string:
        payload["query_hash"] = hashlib.sha512(
            query_string.encode()
        ).hexdigest()
        payload["query_hash_alg"] = "SHA512"
    token = jwt.encode(payload, os.environ["UPBIT_SECRET_KEY"], algorithm="HS256")
    return {"Authorization": f"Bearer {token}"}


# ── API 호출 ────────────────────────────────────────────
def api_get(path: str, params: dict | None = None) -> dict | list:
    url = f"{UPBIT_API}{path}"
    if params:
        url += "?" + "&".join(f"{k}={v}" for k, v in params.items())
    r = requests.get(url, timeout=10)
    r.raise_for_status()
    return r.json()


# ── 기술적 지표 계산 ────────────────────────────────────
def sma(prices: list[float], period: int) -> float:
    window = prices[-period:]
    return sum(window) / len(window)


def ema(prices: list[float], period: int) -> float:
    k = 2 / (period + 1)
    value = prices[0]
    for p in prices[1:]:
        value = p * k + value * (1 - k)
    return value


def rsi(prices: list[float], period: int = 14) -> float:
    if len(prices) < period + 1:
        return 50.0
    gains = losses = 0.0
    for i in range(1, period + 1):
        d = prices[i] - prices[i - 1]
        if d >= 0:
            gains += d
        else:
            losses -= d
    ag, al = gains / period, losses / period
    for i in range(period + 1, len(prices)):
        d = prices[i] - prices[i - 1]
        if d >= 0:
            ag = (ag * (period - 1) + d) / period
            al = (al * (period - 1)) / period
        else:
            ag = (ag * (period - 1)) / period
            al = (al * (period - 1) - d) / period
    return 100.0 if al == 0 else 100 - 100 / (1 + ag / al)


def macd(prices: list[float]) -> dict:
    ema12 = ema(prices, 12)
    ema26 = ema(prices, 26)
    m = ema12 - ema26
    # Signal = MACD의 9일 EMA (간략화)
    s = m * 0.8
    return {"macd": round(m, 2), "signal": round(s, 2), "histogram": round(m - s, 2)}


def bollinger(prices: list[float], period: int = 20) -> dict:
    mid = sma(prices, period)
    window = prices[-period:]
    var = sum((p - mid) ** 2 for p in window) / period
    sd = var**0.5
    return {
        "upper": round(mid + 2 * sd, 2),
        "middle": round(mid, 2),
        "lower": round(mid - 2 * sd, 2),
    }


def stochastic(
    highs: list[float], lows: list[float], closes: list[float], period: int = 14
) -> dict:
    h = max(highs[-period:])
    l = min(lows[-period:])
    c = closes[-1]
    k = 50.0 if h == l else ((c - l) / (h - l)) * 100
    return {"k": round(k, 2), "d": round(k, 2)}


# ── 메인 ────────────────────────────────────────────────
def main(market: str = "KRW-BTC"):
    ticker = api_get("/ticker", {"markets": market})[0]
    daily = api_get("/candles/days", {"market": market, "count": "30"})
    four_h = api_get("/candles/minutes/240", {"market": market, "count": "42"})
    ob = api_get("/orderbook", {"markets": market})[0]
    trades = api_get("/trades/ticks", {"market": market, "count": "100"})

    daily.reverse()  # 오래된 순 정렬
    closes = [c["trade_price"] for c in daily]
    highs = [c["high_price"] for c in daily]
    lows = [c["low_price"] for c in daily]

    buy_vol = sum(t["trade_volume"] for t in trades if t["ask_bid"] == "BID")
    sell_vol = sum(t["trade_volume"] for t in trades if t["ask_bid"] == "ASK")

    snapshot = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S+09:00"),
        "market": market,
        "current_price": ticker["trade_price"],
        "change_rate_24h": ticker["signed_change_rate"],
        "volume_24h": ticker["acc_trade_volume_24h"],
        "indicators": {
            "sma_20": round(sma(closes, 20), 2),
            "ema_10": round(ema(closes, 10), 2),
            "rsi_14": round(rsi(closes, 14), 2),
            "macd": macd(closes),
            "bollinger": bollinger(closes, 20),
            "stochastic": stochastic(highs, lows, closes, 14),
        },
        "orderbook": {
            "bid_total": ob["total_bid_size"],
            "ask_total": ob["total_ask_size"],
            "ratio": round(ob["total_bid_size"] / max(ob["total_ask_size"], 1e-8), 4),
        },
        "trade_pressure": {"buy_volume": buy_vol, "sell_volume": sell_vol},
        "candles_daily": daily,
        "candles_4h": list(reversed(four_h)),
    }
    print(json.dumps(snapshot, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        json.dump({"error": str(e)}, sys.stderr, ensure_ascii=False)
        sys.exit(1)
