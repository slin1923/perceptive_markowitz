module Softlytics

export Analyzer, analyze_pop, get_hists, analyze

using Statistics, LinearAlgebra

mutable struct Analyzer
    eval_space::Matrix{Float64}   # n assets × m closing values
    r_hists::Vector{Float64}      # returns per individual
    v_hists::Vector{Float64}      # volatilities per individual
    s_hists::Vector{Float64}      # Sharpe ratios per individual

    function Analyzer(eval_space::Matrix{Float64})
        new(eval_space, Float64[], Float64[], Float64[])
    end
end

"""
    analyze(analyzer::Analyzer, design::Vector{Float64})

Analyze a single portfolio design vector `[w..., t]`.
"""
function analyze(analyzer, design::Vector{Float64})
    n = size(analyzer.eval_space, 1)
    weights = design[1:n]
    t = Int(round(design[end]))

    data = analyzer.eval_space[:, end-t+1:end]

    rets = diff(log.(data), dims=2)

    expected_returns = t * mean(rets, dims=2)

    cov_matrix = t * cov(permutedims(rets))

    portfolio_return = dot(expected_returns, weights)
    portfolio_volatility = sqrt(0.5 * weights' * cov_matrix * weights)

    sharpe_ratio = portfolio_return / portfolio_volatility

    return expected_returns, cov_matrix, portfolio_return, portfolio_volatility, sharpe_ratio
end

"""
    analyze_pop(analyzer::Analyzer, portpop::Matrix{Float64})

Evaluate a population of portfolio designs.

Updates the analyzer's stored return, volatility, and Sharpe histories.
"""
function analyze_pop(analyzer, portpop::Matrix{Float64})
    k = size(portpop, 1)

    r_hist = Float64[]
    v_hist = Float64[]
    s_hist = Float64[]

    for i in 1:k
        _, _, r, v, s = analyze(analyzer, portpop[i, :])
        push!(r_hist, r)
        push!(v_hist, v)
        push!(s_hist, s)
    end

    analyzer.r_hists = r_hist
    analyzer.v_hists = v_hist
    analyzer.s_hists = s_hist

    return r_hist, v_hist, s_hist
end

function get_hists(analyzer)
    return analyzer.r_hists, analyzer.v_hists, analyzer.s_hists
end

end