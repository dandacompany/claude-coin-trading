#!/usr/bin/env python3
"""
Upbit 매매 실행 스크립트

안전장치:
  - EMERGENCY_STOP=true → 모든 매매 차단
  - DRY_RUN=true → 분석만 수행, 실제 주문 미실행
  - MAX_TRADE_AMOUNT → 1회 매매 금액 상한

사용법:
  python3 scripts/execute_trade.py bid KRW-BTC 100000   # 시장가 매수 (10만원)
  python3 scripts/execute_trade.py ask KRW-BTC 0.001    # 시장가 매도 (0.001 BTC)

출력: JSON (stdout)
"""

import hashlib
import json
import os
import sys
import time
import uuid
from urllib.parse import urlencode

import jwt
import requests

UPBIT_API = "https://api.upbit.com/v1"


def make_auth_header(query_string: str) -> dict:
    payload = {
        "access_key": os.environ["UPBIT_ACCESS_KEY"],
        "nonce": str(uuid.uuid4()),
        "timestamp": int(time.time() * 1000),
        "query_hash": hashlib.sha512(query_string.encode()).hexdigest(),
        "query_hash_alg": "SHA512",
    }
    token = jwt.encode(payload, os.environ["UPBIT_SECRET_KEY"], algorithm="HS256")
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def execute(side: str, market: str, amount: str):
    ts = time.strftime("%Y-%m-%dT%H:%M:%S+09:00")

    # 1) 긴급 정지 확인
    if os.environ.get("EMERGENCY_STOP", "false").lower() == "true":
        return {
            "success": False,
            "dry_run": False,
            "side": side,
            "market": market,
            "amount": amount,
            "error": "EMERGENCY_STOP 활성화 - 매매 차단",
            "timestamp": ts,
        }

    # 2) DRY_RUN 확인
    if os.environ.get("DRY_RUN", "true").lower() == "true":
        return {
            "success": True,
            "dry_run": True,
            "side": side,
            "market": market,
            "amount": amount,
            "timestamp": ts,
        }

    # 3) 매수 금액 상한 확인
    max_amount = int(os.environ.get("MAX_TRADE_AMOUNT", "100000"))
    if side == "bid" and int(float(amount)) > max_amount:
        return {
            "success": False,
            "dry_run": False,
            "side": side,
            "market": market,
            "amount": amount,
            "error": f"매매 금액 상한 초과: {amount} > {max_amount}",
            "timestamp": ts,
        }

    # 4) 주문 실행
    body = {"market": market, "side": side}
    if side == "bid":
        body["ord_type"] = "price"  # 시장가 매수
        body["price"] = amount
    else:
        body["ord_type"] = "market"  # 시장가 매도
        body["volume"] = amount

    qs = urlencode(body)
    headers = make_auth_header(qs)

    r = requests.post(f"{UPBIT_API}/orders", json=body, headers=headers, timeout=10)
    response = r.json()

    return {
        "success": r.ok,
        "dry_run": False,
        "side": side,
        "market": market,
        "amount": amount,
        "response": response,
        "error": None if r.ok else json.dumps(response, ensure_ascii=False),
        "timestamp": ts,
    }


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(
            "사용법: python3 execute_trade.py [bid|ask] [market] [amount]",
            file=sys.stderr,
        )
        sys.exit(1)

    result = execute(sys.argv[1], sys.argv[2], sys.argv[3])
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if not result["success"]:
        sys.exit(1)
