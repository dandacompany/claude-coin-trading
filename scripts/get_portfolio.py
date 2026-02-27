#!/usr/bin/env python3
"""
Upbit 포트폴리오 조회 스크립트

조회 항목:
  - KRW 잔고
  - 보유 암호화폐 목록, 수량, 평균매수가, 현재가, 평가액, 수익률
  - 전체 포트폴리오 평가

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


def make_auth_header() -> dict:
    payload = {
        "access_key": os.environ["UPBIT_ACCESS_KEY"],
        "nonce": str(uuid.uuid4()),
        "timestamp": int(time.time() * 1000),
    }
    token = jwt.encode(payload, os.environ["UPBIT_SECRET_KEY"], algorithm="HS256")
    return {"Authorization": f"Bearer {token}"}


def main():
    # 잔고 조회
    r = requests.get(
        f"{UPBIT_API}/accounts", headers=make_auth_header(), timeout=10
    )
    r.raise_for_status()
    accounts = r.json()

    krw_balance = 0.0
    holdings = []
    markets = []

    for acc in accounts:
        if acc["currency"] == "KRW":
            krw_balance = float(acc["balance"])
            continue
        bal = float(acc["balance"])
        if bal > 0:
            markets.append(f"KRW-{acc['currency']}")
            holdings.append(
                {
                    "currency": acc["currency"],
                    "balance": bal,
                    "avg_buy_price": float(acc["avg_buy_price"]),
                    "current_price": 0,
                    "eval_amount": 0,
                    "profit_loss_pct": 0.0,
                }
            )

    # 보유 종목 현재가 조회
    if markets:
        r2 = requests.get(
            f"{UPBIT_API}/ticker",
            params={"markets": ",".join(markets)},
            timeout=10,
        )
        for t in r2.json():
            cur = t["market"].replace("KRW-", "")
            h = next((h for h in holdings if h["currency"] == cur), None)
            if h:
                h["current_price"] = t["trade_price"]
                h["eval_amount"] = h["balance"] * t["trade_price"]
                if h["avg_buy_price"] > 0:
                    h["profit_loss_pct"] = round(
                        (t["trade_price"] - h["avg_buy_price"])
                        / h["avg_buy_price"]
                        * 100,
                        2,
                    )

    total_eval = krw_balance + sum(h["eval_amount"] for h in holdings)
    total_invested = sum(h["balance"] * h["avg_buy_price"] for h in holdings)

    snapshot = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S+09:00"),
        "krw_balance": krw_balance,
        "holdings": holdings,
        "total_eval": total_eval,
        "total_invested": total_invested + krw_balance,
        "total_profit_loss_pct": round(
            (total_eval - total_invested - krw_balance) / max(total_invested, 1) * 100,
            2,
        )
        if total_invested > 0
        else 0.0,
    }
    print(json.dumps(snapshot, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        json.dump({"error": str(e)}, sys.stderr, ensure_ascii=False)
        sys.exit(1)
