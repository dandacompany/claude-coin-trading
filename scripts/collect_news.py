#!/usr/bin/env python3
"""
Tavily API를 사용한 암호화폐 뉴스 수집 스크립트

수집: 최근 24시간 BTC 관련 뉴스 최대 10건
감성 분석은 LLM이 수행 (이 스크립트는 수집만 담당)

출력: JSON (stdout)
"""

import json
import os
import sys
from datetime import datetime

import requests

TAVILY_API = "https://api.tavily.com/search"


def main(query: str = "비트코인 Bitcoin BTC 시장"):
    api_key = os.environ.get("TAVILY_API_KEY")
    if not api_key:
        raise RuntimeError("TAVILY_API_KEY 환경변수가 설정되지 않았습니다.")

    r = requests.post(
        TAVILY_API,
        json={
            "api_key": api_key,
            "query": query,
            "search_depth": "advanced",
            "include_answer": False,
            "max_results": 10,
            "topic": "news",
            "days": 1,
        },
        timeout=30,
    )
    r.raise_for_status()

    articles = [
        {
            "title": a.get("title", ""),
            "url": a.get("url", ""),
            "content": (a.get("content", "") or "")[:500],
            "published_date": a.get("published_date", ""),
            "score": a.get("score", 0),
        }
        for a in r.json().get("results", [])
    ]

    result = {
        "timestamp": datetime.now().isoformat(),
        "query": query,
        "articles_count": len(articles),
        "articles": articles,
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        json.dump({"error": str(e)}, sys.stderr, ensure_ascii=False)
        sys.exit(1)
