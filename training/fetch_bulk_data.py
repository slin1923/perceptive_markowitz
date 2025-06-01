# fetch_bulk_data.py 💾🌸
import yfinance as yf
import json
import time
from datetime import datetime, timedelta
from pathlib import Path
from asset_categories import asset_categories  # <-- 🌈 pulled in from separate file!

# 🌸 Create output directory
output_dir = Path(".")  # 💖 current directory, tidy girlie style

# 📅 10 years ago from today
default_start = (datetime.today() - timedelta(days=365 * 10)).strftime("%Y-%m-%d")

# 🪄 Fetch and save data
def fetch_and_save(ticker, category):
    try:
        # shorter history for crypto girlies
        custom_start = "2017-01-01" if category == "crypto" else default_start
        df = yf.download(ticker, start=custom_start, auto_adjust=True)
        time.sleep(2)  # 💤 be kind to the API
        df.columns = [col if isinstance(col, str) else "_".join([str(c) for c in col]).strip() for col in df.columns]
        df = df.reset_index()
        df['Date'] = df['Date'].dt.strftime('%Y-%m-%d') # <-- 💖 MAKE IT JSON-SAFE
        records = df.to_dict(orient='records')

        # ☕ Check if the tea is in the cup
        if len(records) < 100:
            print(f"⚠️ {ticker} ({category}) has only {len(records)} entries. Skipping.")
            return

        # 💾 Save to file
        with open(output_dir / f"{category}_{ticker}.json", "w") as f:
            json.dump(records, f)
        print(f"✅ {ticker} ({category}) saved.")
    except Exception as e:
        print(f"❌ Failed to fetch {ticker} ({category}): {e}")

# 🎯 Pull 10 random tickers per category and fetch
for category, ticker_list in asset_categories.items():
    print(f"✨ Fetching {len(ticker_list)} tickers for category: {category}")
    for ticker in ticker_list:
        fetch_and_save(ticker, category)