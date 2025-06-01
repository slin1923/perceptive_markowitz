module Genetipop

export Evolver

using Random, Statistics, Distributions

# 🧬🎀 Evolver: Handles all things evolution — selection, mutation, crossover, and next-gen glow-ups.
mutable struct Evolver
    population_size::Int
    num_assets::Int
    allow_shorting::Bool
    mutation_rate::Float64
    crossover_rate::Float64
    elite_frac::Float64
    mutation_style::Symbol  # 🎀 options: :gaussian, :flip, :dirichlet
end

"""
    initialize_population(evo::Evolver) -> Matrix{Float64}

🎲 Create the first generation of portfolios!

# Returns
- A `population_size × (num_assets + 1)` matrix:
  - First `num_assets` entries per row are weights (sum to 1, ± allowed by shorting).
  - Last entry is the lookback time `t`, randomly drawn.
"""
function initialize_population(evo::Evolver)
    pop = zeros(Float64, evo.population_size, evo.num_assets + 1)
    for i in 1:evo.population_size
        w = randn(evo.num_assets) # random normal to allow shorting
        if !evo.allow_shorting
            w = abs.(w) # no negative weights if shorting not allowed
        end
        w ./= sum(w)  # Normalize weights to sum to 1
        t = rand(30:250)  # Random holding time in trading days
        pop[i, :] = vcat(w, t)
    end
    return pop
end

"""
💞 Midpoint Crossover: Gently blends two parents into one glam child.

- Weights: midpoint (preserves sum to 1)
- Holding time (t): random pick from parent1.t, parent2.t, or any int in between

Arguments:
- parent1::Vector{Float64}
- parent2::Vector{Float64}
- rate::Float64 🎀 crossover probability

Returns:
- child::Vector{Float64}
"""
function crossover(parent1::Vector{Float64}, parent2::Vector{Float64}, rate::Float64)
    if rand() > rate
        return rand(Bool) ? parent1 : parent2  # no crossover, random clone
    end

    # Split genes
    w1, t1 = parent1[1:end-1], parent1[end]
    w2, t2 = parent2[1:end-1], parent2[end]

    # ✨ Midpoint weights (preserves structure)
    w_child = (w1 + w2) ./ 2
    w_child ./= sum(w_child)  # just to be sure 🎀

    # 🎲 Time gene: randomly choose from [t1, t2] inclusive
    t_min, t_max = min(t1, t2), max(t1, t2)
    t_child = rand(t_min:t_max)

    return vcat(w_child, t_child)
end

"""
💅 mutate_individual(evo::Evolver, indiv::Vector{Float64}) -> Vector{Float64}

✨ Mutation, but make it *fashion*.

Applies a user-selected mutation style to a given portfolio individual while preserving
critical structure — weights always sum to 1, and no negative weights if shorting is disallowed.
This ensures the resulting portfolio remains valid and *fabulous*.

🎀 Mutation styles:
  • :gaussian  → A subtle glam touch. Adds soft noise to each weight for delicate evolution.
                 Negative values are turned positive if shorting is off. Always renormalized.
  • :flip      → Flip two randomly chosen weights like switching accessories on a bold outfit.
                 A simple yet striking mutation for quick shifts in vibe.
  • :dirichlet → Burn it down and start over (but pretty). Replaces weights with a brand new
                 draw from a Dirichlet distribution, ensuring they remain normalized perfection.

⏳ Lookback time is left untouched — she's already living her spontaneous, random life 
     thanks to crossover.

💖 Returns a new individual ready to *serve returns and looks* in the next generation.

"""
function mutate_individual(evo::Evolver, indiv::Vector{Float64})
    weights = copy(indiv[1:end-1])  # 💄 keep the original glam safe
    t = indiv[end]  # ⏳ don't touch the timeline queen (unless asked!)

    # 💤 sometimes you need to skip the drama
    if rand() > evo.mutation_rate
        return indiv  # she's flawless, no notes
    end

    if evo.mutation_style == :gaussian
        # 💋 Soft glam: add a gentle, controlled wiggle
        noise = rand(Normal(0, 0.05), evo.num_assets)
        if !evo.allow_shorting
            noise = abs.(noise)  # we don’t do negativity in this salon 💅
        end
        weights += noise
        weights = max.(weights, 0.0)  # never go below zero, sweetie
        weights ./= sum(weights)  # reblend for balance, always

    elseif evo.mutation_style == :flip
        # 💅 Drama alert: flip two weights like it's a wardrobe change
        i, j = rand(1:evo.num_assets, 2)
        weights[i], weights[j] = weights[j], weights[i]
        # 💫 nothing else changes — just a bold outfit switch

    elseif evo.mutation_style == :dirichlet
        # 🔮 Full rebirth: new girl, new vibe, new allocation
        α = ones(evo.num_assets)  # equal love for all assets
        weights = rand(Dirichlet(α))  # pure, balanced chaos

    else
        error("❌ Unknown mutation style: $(evo.mutation_style). Try :gaussian, :flip, or :dirichlet, hun.")
    end

    return vcat(weights, t)  # 👠 serve looks *and* returns
end

"""
🧬 new_gen(evo::Evolver, pop::Matrix{Float64}, scores::Vector{Float64}; 
           selection_method=:tournament, mutation_method=:gaussian, heat_size::Int=3)

The all-in-one evolution glow-up method 💖

✨ This function:
  1. Selects parent pairs using your chosen method (tournament, truncation, or roulette)
  2. Performs crossover to birth new glam portfolios that respect constraints
  3. Mutates them (lightly or fiercely, depending on your style)
  4. Retains elite individuals based on elite_frac
  5. Returns a sparkling new generation ready to SLAY returns

🎀 Hyperparams:
  • selection_method: Symbol → :tournament | :truncation | :roulette
  • mutation_method: Symbol → :gaussian | :flip | :dirichlet
  • heat_size: Int → Tournament size (if applicable)

👛 Returns:
  • Matrix{Float64} → A full next-generation population
"""
function new_gen(evo::Evolver, pop::Matrix{Float64}, scores::Vector{Float64};
                 selection_method::Symbol = :tournament,
                 mutation_method::Symbol = :gaussian,
                 heat_size::Int = 3)

    k = evo.population_size
    num_assets = evo.num_assets
    num_elite = max(1, round(Int, evo.elite_frac * k))
    new_pop = Matrix{Float64}(undef, k, num_assets + 1)

    # 🎓 Step 1: Keep elites
    sorted_idx = sortperm(scores, rev=true)
    new_pop[1:num_elite, :] = pop[sorted_idx[1:num_elite], :]

    # 🎁 Step 2: Reproduce the rest
    for i in num_elite+1:k
        parent1, parent2 = select_parents(pop, scores, selection_method; frac=evo.elite_frac, heat_size=heat_size)
        child = crossover(parent1, parent2, evo.crossover_rate)
        child = mutate_individual(evo, child, mutation_method)
        new_pop[i, :] = child
    end

    return new_pop
end
