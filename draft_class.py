"""
💾 draft_class.py

Interactively downloads ticker data (one at a time!) from Yahoo Finance using yfinance.
Each valid ticker is saved as a JSON file and plotted for quick visual validation.

🎯 Purpose:
- Allow users to build a custom asset universe.
- Avoid relying on pre-defined asset categories.
- Validate each download visually before optimization.

📍 Output:
- JSON files for each ticker, stored in ./user_data/
- Matplotlib plots showing historical closing prices

✨ Run this script directly in terminal or shell.
"""

import yfinance as yf
import matplotlib.pyplot as plt
import json
import os
import shutil
from datetime import datetime, timedelta

# 🗂 Ensure the output folder exists
if os.path.exists("lineup"):
    shutil.rmtree("lineup")  # remove the folder and all contents
os.makedirs("lineup")  # recreate empty folder

# 📅 10 years ago from today
default_start = (datetime.today() - timedelta(days=365 * 10)).strftime("%Y-%m-%d")

print(
    "🧬✨ Welcome, Quant Queen ✨🧬\n"
    "You're entering Flexible Fetch Mode™.\n"
    "Enter ticker symbols *one at a time* to build your custom portfolio universe.\n"
    "After each download, you'll get a quick plot to validate the data visually. Just close it to move on.\n"
    "When you're satisfied or finished, just type 'done' to wrap it up.\n"
    "bonne chance! 🍀✨\n"
)
print("\n📥 Enter ticker symbols one at a time. Type 'done' to finish.\n")

while True:
    ticker_input = input("🔤 Enter ticker (or 'DONE'): ").strip().upper()

    if ticker_input == "DONE":
        print("\n✅ Ticker input complete.")
        break

    try:
        # 📡 Try to download 5 years of historical data
        df = yf.download(ticker_input, start=default_start, auto_adjust=True)
        if df.empty:
            raise ValueError("No data returned.")

        # 📉 Plot the closing prices
        # 🌙 Set dark background and pastel theme
        plt.style.use("default")  # start clean
        fig, ax = plt.subplots(figsize=(10, 4), facecolor="#1e1e2f")
        ax.set_facecolor("#1e1e2f")

        # 💗 Pastel pink line
        ax.plot(df["Close"], label=ticker_input, color="#FFB6C1", linewidth=2)

        # ✨ Titles and labels in light tones
        ax.set_title(f"{ticker_input} - Closing Prices", color="white", fontsize=14, pad=12)
        ax.set_xlabel("Date", color="white")
        ax.set_ylabel("Price", color="white")

        # 🧊 Soft white grid + legend
        ax.grid(True, linestyle="--", alpha=0.4)
        ax.tick_params(colors="white")
        ax.legend(facecolor="#2e2e3f", edgecolor="white", labelcolor="white")

        plt.tight_layout()
        plt.show()

        # 🧼 Clean up and save as JSON
        df.columns = [col if isinstance(col, str) else "_".join([str(c) for c in col]).strip() for col in df.columns]
        df = df.reset_index()
        df['Date'] = df['Date'].dt.strftime('%Y-%m-%d') # <-- 💖 MAKE IT JSON-SAFE
        records = df.to_dict(orient='records')

        with open(f"lineup/{ticker_input}.json", "w") as f:
            json.dump(records, f)

        print(f"✅ Saved data for {ticker_input}\n")

    except Exception as e:
        print(f"❌ Could not fetch data for {ticker_input}. Error: {e}\n")
