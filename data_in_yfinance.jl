# import_data.jl 🍵📈
using JSON3, DataFrames, Dates

function get_stock_data(ticker::String, start="2023-01-01")
    cmd = `python fetch_data.py $ticker $start`
    output = read(cmd, String)

    if occursin("error", output)
        println("⚠️ Error: ", output)
        return DataFrame()
    end

    parsed = JSON3.read(output)
    df = DataFrame(parsed) 

    return df
end

aapl_data = get_stock_data("AAPL")
print(aapl_data)
