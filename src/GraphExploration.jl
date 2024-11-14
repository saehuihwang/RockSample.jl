module GraphExploration

using LinearAlgebra
using POMDPs
using POMDPTools
using StaticArrays
using Parameters
using Random
using Compose
using Combinatorics
using DiscreteValueIteration
using ParticleFilters

export
    GraphExplorationPOMDP,
    GraphState,
    GraphPos,
    GraphObservation,
    GraphAction,
    apply_action

# Define GraphPos as SVector{2, Int}, similar to RSPos in RockSample
const GraphPos = SVector{2, Int}

"""
    GraphState{MaxVertices, MaxEdges}
Represents the state in a GraphExplorationPOMDP problem.
`MaxVertices` is the number of vertices in the graph.
`MaxEdges` is the number of edges in the graph.

# Fields
- `pos::GraphPos`: The agent's position (x, y).
- `visited_vertices::SVector{MaxVertices, Bool}`: Visited status of vertices.
- `visited_edges::SVector{MaxEdges, Bool}`: Visited status of edges.
"""
struct GraphState{MaxVertices, MaxEdges}
    pos::GraphPos
    visited_vertices::SVector{MaxVertices, Bool}
    visited_edges::SVector{MaxEdges, Bool}
end

"""
    GraphObservation
Represents the observation in the GraphExplorationPOMDP.

# Fields
- `vertex::Union{Int, Nothing}`: Vertex ID or nothing.
- `edge::Union{Int, Nothing}`: Edge ID or nothing.
"""
struct GraphObservation
    vertex::Union{Int, Nothing}
    edge::Union{Int, Nothing}
end

# Define GraphAction as a Union of possible actions
const GraphAction = Union{Symbol, Tuple{Int, Int}}

# Define the POMDP struct with type parameters MaxVertices (number of vertices) and MaxEdges (number of edges)
struct GraphExplorationPOMDP{MaxVertices, MaxEdges} <: POMDP{GraphState{MaxVertices, MaxEdges}, GraphAction, GraphObservation}
    grid_size::Tuple{Int, Int}
    init_pos::GraphPos
    position_to_vertex::Dict{GraphPos, Int}
    position_to_edge::Dict{Tuple{GraphPos, Symbol}, Int}  # Updated to include direction
    discount_factor::Float64
    terminal_state::GraphState{MaxVertices, MaxEdges}
end

# Constructor automatically infers MaxVertices and MaxEdges from grid size
function GraphExplorationPOMDP(; 
    grid_size::Tuple{Int, Int},
    position_to_vertex::Dict{GraphPos, Int},
    position_to_edge::Dict{Tuple{GraphPos, Symbol}, Int},
    init_pos::GraphPos = GraphPos(1, 1),
    discount_factor::Float64 = 0.95
)
    max_vertices = grid_size[1] * grid_size[2]
    max_edges = grid_size[1] * grid_size[2]
    # Create the terminal state based on the actual graph
    terminal_state = GraphState{max_vertices, max_edges}(
        GraphPos(-1, -1),  # Invalid position signifies termination
        SVector{max_vertices, Bool}(fill(true, max_vertices)),
        SVector{max_edges, Bool}(fill(true, max_edges))
    )
    return GraphExplorationPOMDP{max_vertices, max_edges}(
        grid_size, init_pos, position_to_vertex, position_to_edge, discount_factor, terminal_state
    )
end

# POMDP functions

# Discount factor
POMDPs.discount(pomdp::GraphExplorationPOMDP) = pomdp.discount_factor

function POMDPs.isterminal(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}, s::GraphState{MaxVertices, MaxEdges}) where {MaxVertices, MaxEdges}
    return all(s.visited_vertices) && all(s.visited_edges)
end

function POMDPs.initialstate(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}) where {MaxVertices, MaxEdges}
    # Create a uniform distribution over possible initial states
    initial_states = [GraphState{MaxVertices, MaxEdges}(
        pomdp.init_pos,
        SVector{MaxVertices, Bool}(fill(false, MaxVertices)),
        SVector{MaxEdges, Bool}(fill(false, MaxEdges))
    )]
    return SparseCat(initial_states, [1.0])  # Uniform probability
end


# Include other components similar to RockSample.jl
include("states.jl")
include("actions.jl")
include("transition.jl")
include("observations.jl")
include("reward.jl")
include("visualization.jl")  # Optional
# include("heuristics.jl")     # Optional

end  # module