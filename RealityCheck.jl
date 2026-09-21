module RealityCheck

using Statistics, Random, Distributions, LinearAlgebra

export simulate_against_randoms

"""
simulate_against_randoms(eval_space, full_space, opt_weights, opt_t;
                         shorting=false, num_samples=100)
"""
function simulate_against_randoms(eval_space, full_space, opt_weights, opt_t;
                                  shorting=false, num_samples=100)

    # Step 1: Grab real-world performance window
    start_idx = size(eval_space, 2) + 1
    end_idx = start_idx + opt_t - 1
    future_data = full_space[:, start_idx:end_idx]

    # Step 2: Optimized girl stats
    r = mean(opt_weights' * future_data)
    σ² = var(opt_weights' * future_data)
    s = r / sqrt(σ²)
    queen_stats = (ret=r, variance=σ², sharpe=s)

    # Step 3: Random portfolios
    n_assets = length(opt_weights)
    returns = Float64[]
    variances = Float64[]
    sharpes = Float64[]

    for _ in 1:num_samples
        w = shorting ? randn(n_assets) : rand(Dirichlet(n_assets, 1.0))
        w ./= sum(w)
        r_rand = mean(w' * future_data)
        v_rand = var(w' * future_data)
        s_rand = r_rand / sqrt(v_rand)

        push!(returns, r_rand)
        push!(variances, v_rand)
        push!(sharpes, s_rand)
    end

    # Step 4: Percentile dominance 
    percent_higher_return = 100 * count(x -> queen_stats.ret > x, returns) / num_samples
    percent_lower_variance = 100 * count(x -> queen_stats.variance < x, variances) / num_samples
    percent_higher_sharpe = 100 * count(x -> queen_stats.sharpe > x, sharpes) / num_samples

    return (
        queen = queen_stats,
        randoms = (returns=returns, variances=variances, sharpes=sharpes),
        percent_higher_return = percent_higher_return,
        percent_lower_variance = percent_lower_variance,
        percent_higher_sharpe = percent_higher_sharpe,
    )
end

end
