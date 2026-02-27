#!/usr/bin/env python3
"""
Playwright로 Upbit BTC/KRW 차트 캡처 스크립트

headless Chromium을 사용하여 차트를 캡처한다.
data/charts/ 에 타임스탬프 기반 파일명으로 저장한다.

의존성:
  pip install playwright
  playwright install chromium

출력: JSON (stdout)
"""

import asyncio
import json
import os
import sys
from datetime import datetime
from pathlib import Path


async def capture_chart():
    from playwright.async_api import async_playwright

    charts_dir = Path(os.getcwd()) / "data" / "charts"
    charts_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    screenshot_path = str(charts_dir / f"btc_chart_{timestamp}.png")

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            viewport={"width": 1920, "height": 1080},
            locale="ko-KR",
            timezone_id="Asia/Seoul",
        )
        page = await context.new_page()

        await page.goto(
            "https://upbit.com/full_chart?code=CRIX.UPBIT.KRW-BTC",
            wait_until="networkidle",
            timeout=30000,
        )

        # 차트 렌더링 대기
        await page.wait_for_timeout(5000)

        await page.screenshot(path=screenshot_path, full_page=False)
        await browser.close()

    result = {
        "timestamp": datetime.now().isoformat(),
        "chart_path": screenshot_path,
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    try:
        asyncio.run(capture_chart())
    except Exception as e:
        json.dump({"error": str(e)}, sys.stderr, ensure_ascii=False)
        sys.exit(1)
