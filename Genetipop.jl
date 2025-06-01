module Genetipop

export Evolver

using Random, Statistics

# 🧬🎀 Evolver: Handles all things evolution — selection, mutation, crossover, and next-gen glow-ups.
mutable struct Evolver
    population_size::Int
    num_assets::Int
    allow_shorting::Bool
    mutation_rate::Float64
    crossover_rate::Float64
    elite_frac::Float64
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
        w = randn(evo.num_assets)
        if !evo.allow_shorting
            w = abs.(w)
        end
        w ./= sum(w)  # Normalize weights to sum to 1
        t = rand(30:250)  # Random holding time in trading days
        pop[i, :] = vcat(w, t)
    end
    return pop
end

"""
    select_elites(pop::Matrix, scores::Vector, frac::Float64) -> Matrix

👑 Select the top `frac` of the population based on scores (e.g. Sharpe).

# Returns
- Elite subset of the population sorted by score.
"""
function select_elites(pop::Matrix{Float64}, scores::Vector{Float64}, frac::Float64)
    k = size(pop, 1)
    num_elite = max(1, round(Int, frac * k))
    sorted_idx = sortperm(scores, rev=true)
    return pop[sorted_idx[1:num_elite], :]
end

"""
    crossover(parent1::Vector, parent2::Vector, rate::Float64) -> Vector

💞 Blend two parent vectors into a new child.

# Returns
- A new design vector mixed from both parents.
"""
function crossover(parent1::Vector{Float64}, parent2::Vector{Float64}, rate::Float64)
    if rand() > rate
        return rand(Bool) ? parent1 : parent2  # no crossover, pick one
    end
    point = rand(1:length(parent1)-1)  # don't split t
    return vcat(parent1[1:point], parent2[point+1:end])
end

"""
    mutate!(individual::Vector{Float64}, rate::Float64, allow_shorting::Bool)

🌪 Add random spice to an individual (in-place mutation).

- Slightly perturbs weights or lookback time.
"""
function mutate!(individual::Vector{Float64}, rate::Float64, allow_shorting::Bool)
    n = length(individual) - 1
    for i in 1:n
        if rand() < rate
            individual[i] += 0.1 * randn()
        end
    end
    if !allow_shorting
        individual[1:n] .= max.(individual[1:n], 0.0)
    end
    individual[1:n] ./= sum(individual[1:n])  # re-normalize

    if rand() < rate
        individual[end] += rand(-10:10)
        individual[end] = clamp(individual[end], 30, 250)
    end
end

"""
    next_generation(evo::Evolver, old_pop::Matrix{Float64}, scores::Vector{Float64}) -> Matrix{Float64}

🌱 Create a new generation using selection, crossover, and mutation.

# Returns
- A new population matrix.
"""
function next_generation(evo::Evolver, old_pop::Matrix{Float64}, scores::Vector{Float64})
    elites = select_elites(old_pop, scores, evo.elite_frac)
    new_pop = copy(elites)

    while size(new_pop, 1) < evo.population_size
        p1, p2 = rand(elites, 2)
        child = crossover(p1, p2, evo.crossover_rate)
        mutate!(child, evo.mutation_rate, evo.allow_shorting)
        new_pop = vcat(new_pop, reshape(child, 1, :))
    end

    return new_pop
end

end  # module Genetipop 🎀🧬
