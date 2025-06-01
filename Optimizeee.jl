using JSON, Dates
using Glob
using Random

include("Softlytics.jl")  # 🧠 Import Analyzer for data analysis
include("Genetipop.jl")  # 🧬 Import Evolver for evolutionary algorithms
using .Softlytics: Analyzer
using .Genetipop: Evolver

const TRAINING_MODE = false            # 🎀 Toggle this for real vs training mode
const TRAINING_DIR = "training"
const LINEUP_DIR = "lineup"

"""
🧼 fetch_eval_space()

Gathers and sanitizes historical closing price data across user-defined or training tickers.

# Returns
- tickers::Vector{String} – list of tickers used
- prices::Matrix{Float64} – (n_assets × m_days) matrix of close prices
- dates::Vector{Date} – corresponding dates (shared across all tickers)
"""
function fetch_eval_space()
    println("✨ Massaging that data... 💅")

    filepaths = if TRAINING_MODE
        # 🎯 Training mode — randomly draw from a selected category
        desired_category = "blue_chip"  # 🎀 customize this!
        num_tickers = 5                 # 🎀 customize this too!

        all_jsons = filter(f -> endswith(f, ".json") && startswith(basename(f), desired_category * "_"),
                           Glob.glob("$TRAINING_DIR/*.json"))

        if length(all_jsons) < num_tickers
            error("Not enough files in category '$desired_category' to draw $num_tickers tickers.")
        end

        Random.shuffle(all_jsons)[1:num_tickers]

    else
        # 🧑‍💻 User-defined mode — populate lineup dynamically via draft_class.py
        println("📡 Running Python script to fetch fresh tickers...")
        run(`python draft_class.py`)
        sleep(1.0)  # 💨 lil breather to let the files settle in

        filter(f -> endswith(f, ".json"), Glob.glob("$LINEUP_DIR/*.json"))
    end

    # 📥 Parse each JSON file
    ticker_data = Dict{String, Vector{Float64}}()
    date_sets = Vector{Vector{Date}}()

    for file in filepaths
        raw = JSON.parsefile(file)
        if isempty(raw)
            println("⚠️ Warning: Skipping empty file $file")
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

    # 🧵 Trim all to shortest history length
    min_len = minimum(length.(values(ticker_data)))
    tickers = collect(keys(ticker_data))
    clipped_prices = hcat([ticker_data[t][end-min_len+1:end] for t in tickers]...)'
    clipped_dates = date_sets[argmin(length.(date_sets))][end-min_len+1:end]

    # 📅 Double-check date alignment
    for d in date_sets
        if d[end-min_len+1:end] != clipped_dates
            error("⛔ Date misalignment detected across tickers! Make sure your data is synchronized.")
        end
    end

    println("✅ Data massaged and aligned. Assets: $(length(tickers)), Days: $min_len")
    return tickers, clipped_prices, clipped_dates
end

# ✨ Main Test Function ✨
function test_fetch_eval_space()
    println("🧠 Launching Optimizeee.jl...")

    # 🚀 Fetch and clean evaluation space
    tickers, prices, dates = fetch_eval_space()

    # 📋 Display results
    println("\n🌟 Tickers used:")
    println(tickers)

    println("\n🧾 Price matrix size (assets × days):")
    println(size(prices))

    println("\n🔍 Sample price matrix (first 3 assets × first 5 days):")
    display(prices[1:min(end, 3), 1:min(end, 5)])

    println("\n📆 Sample dates (first 5):")
    println(dates[1:min(end, 5)])
end

function main()
    # Load data, align JSONs, create eval_space...
    tickers, eval_space, dates = fetch_eval_space()

    # 🎀 Instantiate your Analyzer bestie
    analyzer = Analyzer(eval_space)

    # 🎀 GENETIC ENGINE HYPERPARAMETER KNOBS
    evolver = Evolver(
    population_size = 100,
    num_assets = size(eval_space, 1),
    allow_shorting = false,
    mutation_rate = 0.1,
    crossover_rate = 0.8,
    elite_frac = 0.1,
)

    println("🧠 Analyzer and 🧬 Evolver are initialized and ready to werk 💅")
end

# 🏁 Run the main function if this file is the entry point
# test_fetch_eval_space()
main()