using JSON, Dates
using Glob
using Statistics, Random
using Plots, Measures

include("Softlytics.jl")
include("Genetipop.jl")
include("Visualette.jl")
include("RealityCheck.jl")
include("WindowCheck.jl")

using .Softlytics
using .Genetipop
using .Visualette
using .RealityCheck
using .WindowCheck

const TRAINING_MODE = true
const TRAINING_DIR = "training"
const LINEUP_DIR = "lineup"

"""
Fetch and align historical closing price data.

Returns:
    tickers: List of tickers.
    prices: n_assets × m_days matrix of closing prices.
    dates: Corresponding dates.
    min_len: Common history length.
"""
function fetch_eval_space()

    println("Loading historical data...")

    filepaths = String[]

    if TRAINING_MODE
        # Randomly select tickers from a category
        desired_category = "bonds"
        num_tickers = 10

        all_jsons = filter(
            f -> endswith(f, ".json") && startswith(basename(f), desired_category * "_"),
            Glob.glob("$TRAINING_DIR/*.json")
        )

        if length(all_jsons) < num_tickers
            error("Not enough files in category '$desired_category' to draw $num_tickers tickers.")
        end

        filepaths = Random.shuffle(all_jsons)[1:num_tickers]
        println("Training mode: selected $num_tickers tickers from category '$desired_category'.")
        sleep(1.0)
    else
        println("Fetching fresh tickers...")
        run(`python draft_class.py`)
        sleep(1.0)

        filepaths = filter(f -> endswith(f, ".json"), Glob.glob("$LINEUP_DIR/*.json"))
    end

    ticker_data = Dict{String, Vector{Float64}}()
    date_sets = Vector{Vector{Date}}()

    for file in filepaths
        raw = JSON.parsefile(file)

        if isempty(raw)
            println("Warning: skipping empty file $file")
            continue
        end

        json_keys = collect(keys(raw[1]))
        close_key = filter(k -> startswith(k, "Close_"), json_keys)[1]
        ticker = replace(close_key, "Close_" => "")

        closes = Float64[]
        dates = Date[]

        for entry in raw
            push!(closes, entry[close_key])
            push!(dates, Date(entry["Date"]))
        end

        ticker_data[ticker] = closes
        push!(date_sets, dates)
    end

    # Trim all series to the shortest history
    min_len = minimum(length.(values(ticker_data)))
    tickers = collect(keys(ticker_data))
    clipped_prices = hcat([ticker_data[t][end-min_len+1:end] for t in tickers]...)'
    clipped_dates = date_sets[argmin(length.(date_sets))][end-min_len+1:end]

    # Verify date alignment
    for d in date_sets
        if d[end-min_len+1:end] != clipped_dates
            error("Date misalignment detected across tickers. Make sure the data is synchronized.")
        end
    end

    println("Data loaded: $(length(tickers)) assets, $min_len days.")
    sleep(1.0)

    return tickers, clipped_prices, clipped_dates, min_len
end


function run_one()

    tickers, full_space, dates, hist_avail = fetch_eval_space()

    evolver = Evolver(
        100,
        size(full_space, 1);
        allow_shorting = false,
        mutation_rate = 0.9,
        mutation_style = :dirichlet,
        crossover_rate = 1.0,
        elite_frac = 0.03,
        selection_method = :roulette,
        heat_size = 5,
        t_min = 1,
        t_max = floor(Int, hist_avail / 2),
    )

    println("Maximum lookback period: $(evolver.t_max) days")

    # Use only the training portion of the history
    eval_space = full_space[:, 1:end - evolver.t_max]

    analyzer = Analyzer(Matrix(eval_space))

    println("Evolver and analyzer initialized.")

    max_generations = 1e5
    max_stall = 1e3
    stall_counter = 0
    best_sharpe = -Inf
    prev_best_sharpe = -Inf

    sharpe_log = Float64[]
    return_log = Float64[]
    variance_log = Float64[]
    weights_log = Vector{Vector{Float64}}()
    t_log = Int[]

    population = initialize_population(evolver)

    for generation in 1:max_generations

        println("Generation $generation")

        analyze_pop(analyzer, population)
        r_hist, v_hist, s_hist = get_hists(analyzer)

        best_idx = argmax(s_hist)
        best_sharpe = s_hist[best_idx]
        best_return = r_hist[best_idx]
        best_variance = v_hist[best_idx]
        best_design = population[best_idx, :]

        weights = best_design[1:end-1]
        t = best_design[end]

        log_new = isempty(sharpe_log) || (
            best_sharpe != last(sharpe_log) ||
            best_return != last(return_log) ||
            best_variance != last(variance_log) ||
            weights != last(weights_log) ||
            t != last(t_log)
        )

        if log_new
            push!(sharpe_log, best_sharpe)
            push!(return_log, best_return)
            push!(variance_log, best_variance)
            push!(weights_log, copy(weights))
            push!(t_log, t)
        end

        println("Best Sharpe: $(round(best_sharpe, digits=5))")
        # println("Best Design: ", best_design)

        # Check for improvement
        if best_sharpe > prev_best_sharpe
            stall_counter = 0
            prev_best_sharpe = best_sharpe
        else
            stall_counter += 1
            println("No improvement: $stall_counter/$max_stall")

            if stall_counter >= max_stall
                println("Converged after $generation generations. Sharpe ≈ $(round(best_sharpe, digits=5))")
                break
            end
        end

        population = new_gen(evolver, population, s_hist)
    end

    println("Evolution complete.")

    evo_log = (
        sharpe = sharpe_log,
        returns = return_log,
        variances = variance_log,
        weights = weights_log,
        ts = t_log,
    )

    in_window = benchmark_against_randoms(
        analyzer,
        [weights_log[end]; t_log[end]],
        evolver.t_min,
        evolver.t_max;
        shorting = evolver.allow_shorting,
        num_samples = 1000,
    )

    println("----- In-Window Benchmark Results -----")
    println("Outperformed Return:   $(round(in_window.percent_higher_return, digits=2))%")
    println("Outperformed Variance: $(round(in_window.percent_lower_variance, digits=2))%")
    println("Outperformed Sharpe:   $(round(in_window.percent_higher_sharpe, digits=2))%")

    results = simulate_against_randoms(
        eval_space,
        full_space,
        weights_log[end],
        t_log[end];
        shorting = evolver.allow_shorting,
        num_samples = 1000
    )

    println("----- Reality Check vs Random Portfolios -----")
    println("Percent of randoms outperformed in return: $(round(results.percent_higher_return, digits=2))%")
    println("Percent of randoms outperformed in Sharpe: $(round(results.percent_higher_sharpe, digits=2))%")
    println("Percent of randoms outperformed in variance: $(round(results.percent_lower_variance, digits=2))%")

    Visualette.show_evolution(evo_log)
    Visualette.show_realitycheck(results)
    Visualette.show_windowcheck(in_window)

    println()
    println("----- Results -----")
    println("Recommended Portfolio Weights: $(round.(weights_log[end], digits=4))")
    println("Recommended Holding Time: $(t_log[end]) days")
    println("Optimization complete.")
end


function run_quick()

    tickers, full_space, _, hist_avail = fetch_eval_space()

    evolver = Evolver(
        100, size(full_space, 1);
        allow_shorting = false,
        mutation_rate = 0.9,
        mutation_style = :dirichlet,
        crossover_rate = 1.0,
        elite_frac = 0.03,
        selection_method = :roulette,
        heat_size = 5,
        t_min = 1,
        t_max = floor(Int, hist_avail / 2),
    )

    eval_space = full_space[:, 1:end - evolver.t_max]
    analyzer = Analyzer(Matrix(eval_space))

    max_generations = 1e5
    max_stall = 50
    stall_counter = 0
    best_sharpe = -Inf
    prev_best_sharpe = -Inf
    population = initialize_population(evolver)

    for generation in 1:max_generations
        analyze_pop(analyzer, population)
        r_hist, v_hist, s_hist = get_hists(analyzer)

        best_idx = argmax(s_hist)
        best_sharpe = s_hist[best_idx]

        if best_sharpe > prev_best_sharpe
            stall_counter = 0
            prev_best_sharpe = best_sharpe
        else
            stall_counter += 1

            if stall_counter >= max_stall
                break
            end
        end

        population = new_gen(evolver, population, s_hist)
    end

    best_idx = argmax(get_hists(analyzer)[3])
    best_design = population[best_idx, :]

    weights = best_design[1:end-1]
    t = best_design[end]

    in_window = benchmark_against_randoms(
        analyzer,
        [weights; t],
        evolver.t_min,
        evolver.t_max;
        shorting = evolver.allow_shorting,
        num_samples = 1000
    )

    results = simulate_against_randoms(
        eval_space,
        full_space,
        weights,
        Int(round(t));
        shorting = evolver.allow_shorting,
        num_samples = 1000
    )

    return (
        in_return = in_window.percent_higher_return,
        in_var = in_window.percent_lower_variance,
        in_sharpe = in_window.percent_higher_sharpe,
        rc_return = results.percent_higher_return,
        rc_var = results.percent_lower_variance,
        rc_sharpe = results.percent_higher_sharpe,
    )
end


function run_looped_quick_trials(n::Int = 10)

    in_returns = Float64[]
    in_vars = Float64[]
    in_sharpes = Float64[]
    rc_returns = Float64[]
    rc_vars = Float64[]
    rc_sharpes = Float64[]

    for i in 1:n
        println("Running quick trial $i/$n...")
        res = run_quick()

        push!(in_returns, res.in_return)
        push!(in_vars, res.in_var)
        push!(in_sharpes, res.in_sharpe)
        push!(rc_returns, res.rc_return)
        push!(rc_vars, res.rc_var)
        push!(rc_sharpes, res.rc_sharpe)
    end

    p1 = histogram(
        in_returns,
        bins=30,
        alpha=0.5,
        label="In-Window",
        c=:deepskyblue,
        title="Returns",
        xlabel="% Outperformed"
    )
    histogram!(rc_returns, bins=30, alpha=0.5, label="Reality", c=:hotpink)

    p2 = histogram(
        in_vars,
        bins=30,
        alpha=0.5,
        label="In-Window",
        c=:deepskyblue,
        title="Variances",
        xlabel="% Outperformed"
    )
    histogram!(rc_vars, bins=30, alpha=0.5, label="Reality", c=:hotpink)

    p3 = histogram(
        in_sharpes,
        bins=30,
        alpha=0.5,
        label="In-Window",
        c=:deepskyblue,
        title="Sharpe Ratios",
        xlabel="% Outperformed"
    )
    histogram!(rc_sharpes, bins=30, alpha=0.5, label="Reality", c=:hotpink)

    plot_final = plot(
        p1, p2, p3,
        layout=(1,3),
        size=(1200, 500),
        legend=true,
        bottom_margin=8mm
    )

    savefig(plot_final, "quick_runs_summary.png")
end

# Run the main function if this file is the entry point
# run_one()

run_looped_quick_trials(100)