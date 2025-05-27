using HTTP, JSON, DataFrames
using Dates
using Plots

my_colors = [
    :hotpink,        # 1. pink 💖
    :skyblue,        # 2. soft blue 💙
    :mediumaquamarine, # 3. mint green 🌿
    :plum,
    :thistle,
    :peachpuff,
    :lightcoral,
    :lavender,
    :palegreen,
    :lightsalmon
]

function fetch_data(symbol::String, apikey::String)
    url = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$(symbol)&apikey=$(apikey)"
    res = HTTP.get(url)
    data = JSON.parse(String(res.body))
    return data
end

function fetch_mult_data(symbols::Vector{String}, apikey::String)
    stock_data = Dict()
    for symbol in symbols
        println("Fetching data for $symbol...")
        data = fetch_data(symbol, apikey)
        stock_data[symbol] = data
        sleep(12)  # ~5 calls per minute limit = 12 sec delay
    end
    return stock_data
end

function dataFramize(all_data::Dict)
    dfs = DataFrame[]  # store individual DataFrames

    for (symbol, stock_data) in all_data
        ts = stock_data["Time Series (Daily)"]
        dates = Date[]
        opens = Float64[]
        highs = Float64[]
        lows = Float64[]
        closes = Float64[]
        volumes = Int[]

        for (date_str, values) in ts
            push!(dates, Date(date_str, dateformat"yyyy-mm-dd"))
            push!(opens, parse(Float64, values["1. open"]))
            push!(highs, parse(Float64, values["2. high"]))
            push!(lows, parse(Float64, values["3. low"]))
            push!(closes, parse(Float64, values["4. close"]))
            push!(volumes, parse(Int, values["5. volume"]))
        end

        df = DataFrame(
            symbol = fill(symbol, length(dates)),
            date = dates,
            open = opens,
            high = highs,
            low = lows,
            close = closes,
            volume = volumes
        )
        sort!(df, :date)
        push!(dfs, df)
    end

    return vcat(dfs...)  # combine all into one big DF
end

function plot_all_stocks(df::DataFrame)
    symbols = unique(df.symbol)
    plt = plot(title = "Multi-Stock Glow-Up Plot",
               xlabel = "Date",
               ylabel = "Closing Price",
               legend = :topright,
               lw = 3,
               palette = :pastel)

    for (i,sym) in enumerate(symbols)
        subdf = df[df.symbol .== sym, :]
        color = my_colors[mod1(i, length(my_colors))]
        plot!(plt, subdf.date, subdf.close, label = sym, color=color)
    end

    display(plt)
end

# example:
symbols = ["AAPL", "TSLA", "AMZN"]
all_data = fetch_mult_data(symbols, "GPS6YB9HPQCVJAHM") # data comes out in dictionary format
df = dataFramize(all_data)
plot_all_stocks(df)
print(df)
