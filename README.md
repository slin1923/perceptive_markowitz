# A Perceptive Markowitz Model 💸💰🤑
Repo for "A Perceptive Markowitz Model" (AA222/CS361 Stanford Final)

Requirements: 
- Julia 🎀 v 1.9.3+
- Python 🐍 v 3.11.5+
- pip install the requirements.txt file
- activate the Julia environment 

A Perceptive Markowitz Model is a portfolio optimizer that takes a list of assets-of-interest and produces the optimal weights for each.  Stress no more about how to allocate your funds across a portfolio, APMM does it for you!  

You can opt to consider or not consider short-selling.  
You can also opt to calculate or not calculate best and worst case scenarios. 

---

**AUTHOR**: Sean Lin (seanlin@stanford.edu)

--- 

**INPUTS**: List of assets-of-interest (Ex: [GOOG, TSLA, NVDA, COST])
  - Practical Note: This model does not make any decisions for you regarding the assets you choose to buy.  The set of assets this model considers is 100% up to the best judgement of the user. You may educate your list of assets based on the news, historical data, or recommendations from your unemployed uncle.  The expected returns of the model are fundamentally influenced by the set of assets given as an input.  

**OUTPUTS**: 
1. list of recommended weights (Ex: [0.2, 0.3, 0.4, 0.1]) 
  - Constraint: all weights must sum to 1
  - If shorting is active, weights can be negative.  If shorting is inactive, weights must strictly be positive.
2. holding time: (Ex: 26 days)
3. best and worst case returns
  - Optional, requires simulations rather than a purely reactive model

---
**RUNNING NOTES**

aesthetic✨ plots I want
- overlaid weights vs epoch
- holding time vs epoch
- Objective func (Sharpe Ratio) vs epoch
- GP confidence range

evaluation metrics
- opt Sharpe to n random Sharpes
- opt returns to avg n random returns
- Sharpe-Return efficiency plot (multiobjective metric on both sharpe ratio AND returns with frontier)
- out-of-sample dominance rate (how well does this portfolio work on other samples)

usage and FLOW 🌊
- input portfolio
  - BACKEND: extract all data, 
- do you want to allow shorting?  
  - if no: good responsible trader 🤭
  - if yes: How wild r u? (do you want a shorting limit)
    - BACKEND: set l-infinity norm on design vector
- note on relevant price for optimization
  - by default, will optimize on CLOSING PRICE
  - if desired, allow user the freedom to optimize on OPENING PRICES, HIs, or LOs.  but disclaimer that this tool is not designed for high-frequency intra-day trading anyways, so this metric really shouldn't matter. 
- optimize on Expectation, or best/worst case
  - adjust surrogate objective function as fit
  - keep data on the other metrics anyways, will be useful for result visualization


