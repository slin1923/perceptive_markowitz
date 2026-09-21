module Genetipop

export Evolver, initialize_population, select_parents, crossover, mutate_individual, new_gen

using Random, Statistics, Distributions, StatsBase

mutable struct Evolver
    population_size::Int
    num_assets::Int
    allow_shorting::Bool

    # Mutation parameters
    mutation_rate::Float64
    mutation_style::Symbol

    # Crossover parameters
    crossover_rate::Float64

    # Selection parameters
    elite_frac::Float64
    selection_method::Symbol
    heat_size::Int

    # Holding time parameters
    t_min::Int
    t_max::Int

    """
    Evolver constructor.

    Defaults:
        allow_shorting = false
        mutation_rate = 0.1
        mutation_style = :gaussian
        crossover_rate = 0.7
        elite_frac = 0.2
        selection_method = :tournament
        heat_size = 5
        t_min = 30
        t_max = 250
    """
    function Evolver(population_size::Int, num_assets::Int;
                     allow_shorting::Bool = false,
                     mutation_rate::Float64 = 0.1,
                     mutation_style::Symbol = :gaussian,
                     crossover_rate::Float64 = 0.7,
                     elite_frac::Float64 = 0.2,
                     selection_method::Symbol = :tournament,
                     heat_size::Int = 5, 
                     t_min::Int = 30, t_max::Int = 250)
        return new(population_size, num_assets, allow_shorting,
                   mutation_rate, mutation_style,
                   crossover_rate, elite_frac,
                   selection_method, heat_size, t_min, t_max)
    end
end

"""
initialize_population(evo::Evolver) -> Matrix{Float64}

Returns a population where each row contains asset weights followed by
a randomly generated holding time.
"""
function initialize_population(evo::Evolver)
    pop = zeros(Float64, evo.population_size, evo.num_assets + 1)

    for i in 1:evo.population_size
        w = randn(evo.num_assets)
        if !evo.allow_shorting
            w = abs.(w)
        end

        w ./= sum(w)
        t = rand(evo.t_min:evo.t_max)
        pop[i, :] = vcat(w, t)
    end

    return pop
end

"""
Select two parents using the configured selection method.
"""
function select_parents(evo::Evolver, pop::Matrix{Float64}, scores::Vector{Float64})
    method = evo.selection_method
    frac = evo.elite_frac
    heat_size = evo.heat_size

    k = size(pop, 1)
    selected_idxs = Int[]

    if method == :truncation
        num_elite = max(1, round(Int, frac * k))
        elite_idxs = sortperm(scores, rev=true)[1:num_elite]
        selected_idxs = rand(elite_idxs, 2)

    elseif method == :tournament
        for _ in 1:2
            contestants = rand(1:k, heat_size)
            best = argmax(scores[contestants])
            push!(selected_idxs, contestants[best])
        end

    elseif method == :roulette
        clean_scores = copy(scores)

        for i in eachindex(clean_scores)
            if !isfinite(clean_scores[i])
                clean_scores[i] = 0
            end
        end

        shifted = clean_scores .- minimum(clean_scores)
        shifted .+= 1e-6
        probs = shifted ./ sum(shifted)
        selected_idxs = sample(1:k, Weights(probs), 2; replace=false)

    else
        error("Unknown selection method: $method")
    end

    return (pop[selected_idxs[1], :], pop[selected_idxs[2], :])
end

"""
Midpoint crossover.

Weights are averaged and the holding time is randomly selected from the
range between the two parent values.
"""
function crossover(evo::Evolver, parent1::Vector{Float64}, parent2::Vector{Float64})
    if rand() > evo.crossover_rate
        return rand(Bool) ? parent1 : parent2
    end

    w1, t1 = parent1[1:end-1], parent1[end]
    w2, t2 = parent2[1:end-1], parent2[end]

    w_child = (w1 + w2) ./ 2
    w_child ./= sum(w_child)

    t_min, t_max = min(t1, t2), max(t1, t2)
    t_child = rand(t_min:t_max)

    return vcat(w_child, t_child)
end

"""
mutate_individual(evo::Evolver, indiv::Vector{Float64}) -> Vector{Float64}

Applies the configured mutation style while preserving valid portfolio
weights. Holding time is regenerated when mutation occurs.
"""
function mutate_individual(evo::Evolver, indiv::Vector{Float64})
    weights = copy(indiv[1:end-1])
    t = indiv[end]

    if rand() > evo.mutation_rate
        return indiv
    end

    if evo.mutation_style == :gaussian
        noise = rand(Normal(0, 0.05), evo.num_assets)

        if !evo.allow_shorting
            noise = abs.(noise)
        end

        weights += noise
        weights = max.(weights, 0.0)
        weights ./= sum(weights)

    elseif evo.mutation_style == :flip
        i, j = rand(1:evo.num_assets, 2)
        weights[i], weights[j] = weights[j], weights[i]

    elseif evo.mutation_style == :dirichlet
        α = ones(evo.num_assets)
        weights = rand(Dirichlet(α))

    # New holding time
    indiv[end] = rand(evo.t_min:evo.t_max)

    else
        error("Unknown mutation style: $(evo.mutation_style). Try :gaussian, :flip, or :dirichlet, hun.")
    end

    return vcat(weights, t)
end

"""
new_gen(evo::Evolver, pop::Matrix{Float64}, scores::Vector{Float64})

Creates the next generation through selection, crossover, mutation,
and elitism.
"""
function new_gen(evo::Evolver, pop::Matrix{Float64}, scores::Vector{Float64})

    k = evo.population_size
    num_assets = evo.num_assets
    num_elite = max(0, round(Int, evo.elite_frac * k))
    new_pop = Matrix{Float64}(undef, k, num_assets + 1)

    # Keep elites
    sorted_idx = sortperm(scores, rev=true)
    new_pop[1:num_elite, :] = pop[sorted_idx[1:num_elite], :]

    # Reproduce remaining individuals
    for i in num_elite+1:k
        parent1, parent2 = select_parents(evo, pop, scores)
        child = crossover(evo, parent1, parent2)
        child = mutate_individual(evo, child)
        new_pop[i, :] = child
    end

    return new_pop
end

end  # module Genetipop