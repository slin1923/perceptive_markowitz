module Visualette

using Plots

export plot_sharpe_evo, plot_return_evo, plot_variance_evo,
       plot_weight_evo, plot_t_evo, show_evolution

theme(:dark)

default(
    guidefont = font("Fira Sans", 11, :light, "white"),
    tickfont = font("Fira Sans", 9, "white"),
    titlefont = font("Fira Sans", 13, :semibold, "white"),
    legendfont = font("Fira Sans", 9, "white"),
    foreground_color_subplot = :white,
    foreground_color_text = :white,
    gridalpha = 0.3,
    framestyle = :box,
    legend = false,
    dpi = 120
)

pastels = (
    lilac = :mediumorchid1,
    blush = :lightpink1,
    mint = :mediumaquamarine,
    babyblue = :lightskyblue1,
    butter = :lightgoldenrod1,
    cloud = :lavender,
    accent = :thistle
)

function plot_sharpe_evo(log)
    plot(
        log.sharpe,
        title="Sharpe Ratio Evolution",
        xlabel="Checkpoint",
        ylabel="Sharpe Ratio",
        lw=2.5,
        color=pastels.lilac,
        marker=:star5,
        markersize=4
    )
end

function plot_return_evo(log)
    plot(
        log.returns,
        title="Return Evolution",
        xlabel="Checkpoint",
        ylabel="Expected Return",
        lw=2.5,
        color=pastels.butter,
        marker=:circle,
        markersize=4
    )
end

function plot_variance_evo(log)
    plot(
        log.variances,
        title="Variance Evolution",
        xlabel="Checkpoint",
        ylabel="Portfolio Variance",
        lw=2.5,
        color=pastels.babyblue,
        marker=:utriangle,
        markersize=4
    )
end

function plot_weight_evo(log)
    W = hcat(log.weights...)

    heatmap(
        W,
        title="Weight Evolution",
        xlabel="Checkpoint",
        ylabel="Asset Index",
        color=:plasma,
        cbar_title="Weight",
        colorbar=true
    )
end

function plot_t_evo(log)
    plot(
        log.ts,
        title="Holding Period Evolution",
        xlabel="Checkpoint",
        ylabel="Lookback t (days)",
        lw=2.5,
        color=pastels.mint,
        marker=:diamond,
        markersize=4
    )
end

function show_evolution(log)
    p1 = plot_sharpe_evo(log)
    p2 = plot_return_evo(log)
    p3 = plot_variance_evo(log)
    p4 = plot_weight_evo(log)
    p5 = plot_t_evo(log)

    p6 = plot(p1, p2, p3, p4, p5, layout=(3,2), size=(1100,950))
    filename = "glow_up_journey.png"
    savefig(p6, filename)
end

function show_realitycheck(res)
    opt_sharpe = res.queen.sharpe
    opt_return = res.queen.ret
    opt_var = res.queen.variance

    sharpe_hist = histogram(
        res.randoms.sharpes,
        bins=30,
        alpha=0.6,
        label="Randoms",
        title="Sharpe Ratio Comparison",
        xlabel="Sharpe",
        c=:deepskyblue
    )
    vline!([opt_sharpe], label="Opt", lw=3, c=:hotpink)

    return_hist = histogram(
        res.randoms.returns,
        bins=30,
        alpha=0.6,
        label="Randoms",
        title="Return Comparison",
        xlabel="Return",
        c=:mediumspringgreen
    )
    vline!([opt_return], label="Opt", lw=3, c=:hotpink)

    var_hist = histogram(
        res.randoms.variances,
        bins=30,
        alpha=0.6,
        label="Randoms",
        title="Variance Comparison",
        xlabel="Variance",
        c=:lightcoral
    )
    vline!([opt_var], label="Opt", lw=3, c=:hotpink)

    scatter_plot = scatter(
        res.randoms.returns,
        res.randoms.sharpes,
        alpha=0.6,
        label="Randoms",
        xlabel="Return",
        ylabel="Sharpe",
        title="Sharpe vs Return",
        c=:cornflowerblue
    )
    scatter!(
        [opt_return],
        [opt_sharpe],
        label="Opt",
        c=:hotpink,
        marker=:star5,
        markersize=10
    )

    p1 = plot(
        sharpe_hist,
        return_hist,
        var_hist,
        scatter_plot,
        layout=(2,2),
        size=(1000,800),
        legend=true
    )

    filename = "reality_check.png"
    savefig(p1, filename)
end

function show_windowcheck(res)
    opt_sharpe = res.queen.sharpe
    opt_return = res.queen.ret
    opt_var = res.queen.variance

    sharpe_hist = histogram(
        res.randoms.sharpes,
        bins=30,
        alpha=0.6,
        label="Randoms",
        title="Sharpe Ratio Comparison",
        xlabel="Sharpe",
        c=:deepskyblue
    )
    vline!([opt_sharpe], label="Opt", lw=3, c=:orchid)

    return_hist = histogram(
        res.randoms.returns,
        bins=30,
        alpha=0.6,
        label="Randoms",
        title="Return Comparison",
        xlabel="Return",
        c=:mediumspringgreen
    )
    vline!([opt_return], label="Opt", lw=3, c=:orchid)

    var_hist = histogram(
        res.randoms.variances,
        bins=30,
        alpha=0.6,
        label="Randoms",
        title="Variance Comparison",
        xlabel="Variance",
        c=:lightcoral
    )
    vline!([opt_var], label="Opt", lw=3, c=:orchid)

    scatter_plot = scatter(
        res.randoms.returns,
        res.randoms.sharpes,
        alpha=0.6,
        label="Randoms",
        xlabel="Return",
        ylabel="Sharpe",
        title="Sharpe vs Return",
        c=:cornflowerblue
    )
    scatter!(
        [opt_return],
        [opt_sharpe],
        label="Opt",
        c=:orchid,
        marker=:star5,
        markersize=10
    )

    p = plot(
        sharpe_hist,
        return_hist,
        var_hist,
        scatter_plot,
        layout=(2, 2),
        size=(1000, 800),
        legend=true
    )

    savefig(p, "window_check.png")
end

end