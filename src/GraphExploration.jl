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
    GraphObservation,
    GraphAction,
    apply_action
    # Export other functions or types as needed

# Define GraphPos as SVector{2, Int}, similar to RSPos in RockSample
const GraphPos = SVector{2, Int}

"""
    GraphState{NVertices, NEdges}
Represents the state in a GraphExplorationPOMDP problem.
`NVertices` is the number of vertices in the graph.
`NEdges` is the number of edges in the graph.

# Fields
- `pos::GraphPos`: The agent's position (x, y).
- `visited_vertices::SVector{NVertices, Bool}`: Visited status of vertices.
- `visited_edges::SVector{NEdges, Bool}`: Visited status of edges.
"""
struct GraphState{NVertices, NEdges}
    pos::GraphPos
    visited_vertices::SVector{NVertices, Bool}
    visited_edges::SVector{NEdges, Bool}
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

# Define the POMDP struct with type parameters NVertices (number of vertices) and NEdges (number of edges)
@with_kw struct GraphExplorationPOMDP{NVertices, NEdges} <: POMDP{GraphState{NVertices, NEdges}, GraphAction, GraphObservation}
    grid_size::Tuple{Int, Int} = (5, 5)
    init_pos::GraphPos = GraphPos(1, 1)
    position_to_vertex::Dict{GraphPos, Int} = Dict{GraphPos, Int}()
    position_to_edge::Dict{GraphPos, Int} = Dict{GraphPos, Int}()
    discount_factor::Float64 = 0.95
    # Terminal state where all vertices and edges are visited
    terminal_state::GraphState{NV, NE} = GraphState{NV, NE}(
        GraphPos(-1, -1),
        SVector{NV, Bool}(fill(true, NV)),
        SVector{NE, Bool}(fill(true, NE))
    )
    # Additional fields as needed
end

# Constructor to handle cases where position_to_vertex and position_to_edge are provided
function GraphExplorationPOMDP(grid_size::Tuple{Int, Int},
                               position_to_vertex::Dict{GraphPos, Int},
                               position_to_edge::Dict{GraphPos, Int};
                               init_pos::GraphPos = GraphPos(1, 1),
                               discount_factor::Float64 = 0.95,
                               args...)
    num_vertices = maximum(values(position_to_vertex))
    num_edges = maximum(values(position_to_edge))
    return GraphExplorationPOMDP{num_vertices, num_edges}(
        grid_size = grid_size,
        init_pos = init_pos,
        position_to_vertex = position_to_vertex,
        position_to_edge = position_to_edge,
        discount_factor = discount_factor,
        args...
    )
end

# POMDP functions

# Discount factor
POMDPs.discount(pomdp::GraphExplorationPOMDP) = pomdp.discount_factor

# Terminal state check
function POMDPs.isterminal(pomdp::GraphExplorationPOMDP{NVertices, NEdges}, s::GraphState{NVertices, NEdges}) where {NVertices, NEdges}
    return all(s.visited_vertices) && all(s.visited_edges)
end

# Initial state
function POMDPs.initialstate(pomdp::GraphExplorationPOMDP{NVertices, NEdges}) where {NVertices, NEdges}
    visited_vertices = SVector{NVertices, Bool}(fill(false, NVertices))
    visited_edges = SVector{NEdges, Bool}(fill(false, NEdges))
    return GraphState{NVertices, NEdges}(pomdp.init_pos, visited_vertices, visited_edges)
end

# Include other components similar to RockSample.jl
include("states.jl")
include("actions.jl")
include("transition.jl")
include("observations.jl")
include("reward.jl")
include("visualization.jl")  # Optional
include("heuristics.jl")     # Optional

end  # module