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

key variablesss - should live in a main optimization script. 
- portpop: size k * n+1 population of design vectors [w, t]
- eval_space: n*m vector; static per study; farmed data
  - n assets in portofolio
  - m closing value history
  - farmed once from API and stored to prevent yahoo finance from CRASHING OUT
  - should remain static per study

analysis class (pass eval_space); name something cute
- analyze(self.eval_space, design): 
  - returns tuple for a single individual (nx1 vector of expected returns per asset, nxn covolatility matrix, float returns of individual, float volatility of individual, float sharpe ratio with risk-free-rate dropped) *
  - note return tuple is expressed in order required of calculation since subsequent values are dependent on previous values
  - returns and covolatility based on lookback time t which is last element of design vector. 
- analyze_pop(self.eval_space, portpop): uses analyze applied to every individual in portpop.  
  - returns basically the last 3 values of what analyze should return but up-dimensioned to every individual
  - add these values to global class variables r_hists, v_hists, s_hists
- get_hists()
  - simple accessor method for r_hists, v_hists, s_hists


✨plotting library *make these beautiful
- sharpe2sharpe(design, self.randoms, self.eval_space): returns sharpe ratio of design and all sharpe ratios of random designs.  add single evaluation to global history tracker variable for plotting later. 
- returns2returns(design, self.randoms, self.eval_space): same deal but this time with only returns. 
- will add more when needing GP fitting
- sharpe2sharpe_plotter(design_sharpe_hists, rand_sharpes): plot evolution of sharpe ratio of design vs 

a quick tracker for what the json files look like: 
<html>
<body>
<p>[{"Date": "2015-06-01", "Close_BAC": 13.394068717956543, "High_BAC": 13.466906680733567, "Low_BAC": 13.32932403366975, "Open_BAC": 13.41834855342723, "Volume_BAC": 62941600}, {"Date": "2015-06-02", "Close_BAC": 13.531647682189941, "High_BAC": 13.564020787340054, "Low_BAC": 13.35360023476816, "Open_BAC": 13.369786787343218, "Volume_BAC": 65513200}, ...]</p>
</html>
</body>