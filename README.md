# A Perceptive Markowitz Model 💸💰🤑
Repo for "A Perceptive Markowitz Model" (AA222/CS361 Stanford Final)

A Perceptive Markowitz Model is a portfolio optimizer that takes a list of assets-of-interest and produces the optimal weights for each.  Stress no more about how to allocate your funds across a portfolio, APMM does it for you!  

You can opt to consider or not consider short-selling.  
You can also opt to calculate or not calculate best and worst case scenarios. 

---

**AUTHOR**: Sean Lin (seanlin@stanford.edu, 1 909 538 7519)

--- 
**INPUTS**: List of assets-of-interest (Ex: [GOOG, TSLA, NVDA, COST])

**OUTPUTS**: 
1. list of recommended weights (Ex: [0.2, 0.3, 0.4, 0.1]) 
  - Constraint: all weights must sum to 1
  - If shorting is active, weights can be negative.  If shorting is inactive, weights must strictly be positive.
2. holding time: (Ex: 26 days)
3. best and worst case returns
  - Optional, requires simulations rather than a purely reactive model

---
