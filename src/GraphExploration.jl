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
    nx, ny = grid_size
    max_vertices = nx * ny  # One vertex per grid cell
    max_edges = 2 * (nx * (ny - 1)) + 2 * ((nx - 1) * ny)  # Maximum number of edges in the grid up down left right
    # Create the terminal state based on the actual graph
    # Determine which vertices and edges are part of the actual graph
    actual_vertices = Set(values(position_to_vertex))
    actual_edges = Set(values(position_to_edge))
    terminal_state = GraphState{max_vertices, max_edges}(
        GraphPos(-1, -1),  # Invalid position signifies termination
        SVector{max_vertices, Bool}(v in actual_vertices for v in 1:max_vertices),
        SVector{max_edges, Bool}(e in actual_edges for e in 1:max_edges)
    )
    return GraphExplorationPOMDP{max_vertices, max_edges}(
        grid_size, init_pos, position_to_vertex, position_to_edge, discount_factor, terminal_state
    )
end

# POMDP functions

# Discount factor
POMDPs.discount(pomdp::GraphExplorationPOMDP) = pomdp.discount_factor

# Terminal state check
function POMDPs.isterminal(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}, s::GraphState{MaxVertices, MaxEdges}) where {MaxVertices, MaxEdges}
    return s.visited_vertices == pomdp.terminal_state.visited_vertices &&
           s.visited_edges == pomdp.terminal_state.visited_edges
end

# Initial state
function POMDPs.initialstate(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}) where {MaxVertices, MaxEdges}
    visited_vertices = SVector{MaxVertices, Bool}(fill(false, MaxVertices))
    visited_edges = SVector{MaxEdges, Bool}(fill(false, MaxEdges))
    return GraphState{MaxVertices, MaxEdges}(pomdp.init_pos, visited_vertices, visited_edges)
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