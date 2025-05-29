# fetch_data.py 💻✨
import yfinance as yf
import sys
import json
from datetime import datetime

ticker = sys.argv[1]  # 🧃 get the symbol from CLI args
start = sys.argv[2] if len(sys.argv) > 2 else "2023-01-01"

# 📥 Download the data
df = yf.download(ticker, start=start, auto_adjust=True)

# 🧼 Flatten column names in case of MultiIndex (even with one ticker!)
df.columns = [col if isinstance(col, str) else "_".join([str(c) for c in col]).strip() for col in df.columns]

# 🕰 Reset index and convert Timestamp to string
df = df.reset_index()
df['Date'] = df['Date'].dt.strftime('%Y-%m-%d')  # <-- 💖 MAKE IT JSON-SAFE

# 🧃 Convert to dict records and dump to JSON
records = df.to_dict(orient='records')
print(json.dumps(records))