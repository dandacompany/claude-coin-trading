#!/usr/bin/env python3
"""
Crypto Fear & Greed Index 수집 스크립트

소스: Alternative.me (무료, 인증 불필요)
수집: 현재값 + 최근 7일 추이

출력: JSON (stdout)
"""

import json
import sys
from datetime import datetime, timezone

import requests

FGI_API = "https://api.alternative.me/fng/"


def main():
    r = requests.get(FGI_API, params={"limit": "7", "format": "json"}, timeout=10)
    r.raise_for_status()
    data = r.json()["data"]

    history = [
        {
            "date": datetime.fromtimestamp(
                int(d["timestamp"]), tz=timezone.utc
            ).strftime("%Y-%m-%d"),
            "value": int(d["value"]),
            "classification": d["value_classification"],
        }
        for d in data
    ]

    result = {
        "timestamp": datetime.now().isoformat(),
        "current": history[0],
        "history_7d": history,
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        json.dump({"error": str(e)}, sys.stderr, ensure_ascii=False)
        sys.exit(1)
