module WindowCheck
include("Softlytics.jl")

using Statistics, Distributions
using .Softlytics

export benchmark_against_randoms

"""
benchmark_against_randoms(analyzer::Analyzer, opt_design::Vector{Float64}, t_min::Int, t_max::Int;
                          shorting=false, num_samples=1000)

Compares an optimized design `[w..., t]` to random portfolios with random weights and t ∈ [t_min, t_max].

# Returns:
- `queen`: Tuple with (return, variance, sharpe) of the optimized portfolio.
- `randoms`: Dict of sampled returns, variances, and sharpes.
- `percent_*`: Percentage of random portfolios the queen outperformed.
"""
function benchmark_against_randoms(analyzer, opt_design::Vector{Float64}, t_min::Int, t_max::Int;
                                   shorting=false, num_samples=1000)

    n_assets = length(opt_design) - 1

    # 🎓 Get queen stats
    _, _, r_opt, σ_opt, s_opt = analyze(analyzer, opt_design)
    queen_stats = (ret=r_opt, variance=σ_opt^2, sharpe=s_opt)

    # Sample random portfolios
    returns, variances, sharpes = Float64[], Float64[], Float64[]
    for _ in 1:num_samples
        t_rand = rand(t_min:t_max)
        w_rand = shorting ? randn(n_assets) : rand(Dirichlet(ones(n_assets)))
        w_rand ./= sum(w_rand)
        design_rand = [w_rand; t_rand]
        _, _, r, σ, s = analyze(analyzer, design_rand)
        push!(returns, r)
        push!(variances, σ^2)
        push!(sharpes, s)
    end

    # Compare
    percent_higher_return   = 100 * count(x -> r_opt > x, returns) / num_samples
    percent_lower_variance  = 100 * count(x -> σ_opt^2 < x, variances) / num_samples
    percent_higher_sharpe   = 100 * count(x -> s_opt > x, sharpes) / num_samples

    return (
        queen = queen_stats,
        randoms = (returns=returns, variances=variances, sharpes=sharpes),
        percent_higher_return = percent_higher_return,
        percent_lower_variance = percent_lower_variance,
        percent_higher_sharpe = percent_higher_sharpe,
    )
end

end
