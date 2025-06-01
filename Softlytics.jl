module Softlytics

export Analyzer

using Statistics, LinearAlgebra

# 🧠📊 The Analyzer is your brainy bestie:
# Holds your static eval_space and keeps track of Sharpe/return/volatility history across generations.
struct Analyzer
    eval_space::Matrix{Float64}  # ⌛ n assets × m closing values
    r_hists::Vector{Float64}     # 💌 tracked returns per individual
    v_hists::Vector{Float64}     # 💌 tracked volatilities per individual
    s_hists::Vector{Float64}     # 💌 tracked Sharpe ratios per individual

    function Analyzer(eval_space::Matrix{Float64})
        # Initializes an Analyzer with an empty history and a fixed eval_space
        new(eval_space, Float64[], Float64[], Float64[])
    end
end

"""
    analyze(analyzer::Analyzer, design::Vector{Float64}) -> (Vector, Matrix, Float64, Float64, Float64)

💖 Analyze a single portfolio design vector `[w..., t]`.

# Arguments
- `analyzer::Analyzer`: The analysis object containing static eval_space.
- `design::Vector{Float64}`: Portfolio design of length `n+1`:
  - First `n` entries are portfolio weights.
  - Last entry is `t`, the lookback period (number of days).

# Returns
- `expected_returns::Vector{Float64}`: t-day mean log return per asset.
- `cov_matrix::Matrix{Float64}`: t-day covariance matrix (n×n).
- `portfolio_return::Float64`: Expected return of this portfolio over t days.
- `portfolio_volatility::Float64`: Portfolio volatility over t days.
- `sharpe_ratio::Float64`: Return-to-risk ratio (no risk-free rate assumed).
"""
function analyze(analyzer::Analyzer, design::Vector{Float64})
    n = size(analyzer.eval_space, 1)          # number of assets
    weights = design[1:n]                     # portfolio weights (w)
    t = Int(round(design[end]))              # lookback window (t), last element of design

    # 🧪 Grab just the last t days of data
    data = analyzer.eval_space[:, end-t+1:end]

    # 📈 Log returns (dimension: n assets × (t−1) days)
    rets = diff(log.(data), dims=2)

    # 🎯 Time-scaled mean returns for each asset (n×1)
    expected_returns = t * mean(rets, dims=2)

    # 📊 Time-scaled covariance matrix between assets (n×n)
    cov_matrix = t * cov(permutedims(rets))  # make rows = observations for cov()

    # 💸 Portfolio return and risk
    portfolio_return = dot(expected_returns, weights)
    portfolio_volatility = sqrt(0.5 * weights' * cov_matrix * weights)

    # 🌈 Sharpe ratio (assuming zero risk-free rate)
    sharpe_ratio = portfolio_return / portfolio_volatility

    return expected_returns, cov_matrix, portfolio_return, portfolio_volatility, sharpe_ratio
end

"""
    analyze_pop(analyzer::Analyzer, portpop::Matrix{Float64}) -> (Vector, Vector, Vector)

💫 Evaluate a whole population of portfolio designs.

# Arguments
- `analyzer::Analyzer`: Your analysis class instance (with eval_space baked in).
- `portpop::Matrix{Float64}`: Each row is a `[w..., t]` design vector.

# Returns
- `r_hist::Vector{Float64}`: Returns for each portfolio.
- `v_hist::Vector{Float64}`: Volatilities for each portfolio.
- `s_hist::Vector{Float64}`: Sharpe ratios for each portfolio.

Also updates internal `r_hists`, `v_hists`, and `s_hists` fields in `analyzer`.
"""
function analyze_pop(analyzer::Analyzer, portpop::Matrix{Float64})
    k = size(portpop, 1)  # number of individuals in the population

    r_hist = Float64[]  # returns
    v_hist = Float64[]  # volatilities
    s_hist = Float64[]  # Sharpe ratios

    for i in 1:k
        _, _, r, v, s = analyze(analyzer, portpop[i, :])  # ignore returns/covmat, keep the metrics
        push!(r_hist, r)
        push!(v_hist, v)
        push!(s_hist, s)
    end

    # 🧸 Store in your analyzer’s memory for future access
    analyzer.r_hists = r_hist
    analyzer.v_hists = v_hist
    analyzer.s_hists = s_hist

    return r_hist, v_hist, s_hist  # 💌 pass back to caller too
end

# 🧃 get_hists: your softgirl data portal
# Access all stored metrics after analyze_pop has been run 💼✨
function get_hists(analyzer::Analyzer)
    return analyzer.r_hists, analyzer.v_hists, analyzer.s_hists
end

end  # end of the Softlytics module 🎀
