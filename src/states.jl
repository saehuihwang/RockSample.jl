# implementing required state-related functions for the POMDPs.jl framework
# such as state indexing, state reconstruction from indices, and state space iteration.

# Map a state to a unique index.
function POMDPs.stateindex(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}, s::GraphState{MaxVertices, MaxEdges}) where {MaxVertices, MaxEdges}
    if isterminal(pomdp, s)
        return length(pomdp)
    end
    nx, ny = pomdp.grid_size

    # Agent's position index
    pos_index = s.pos[1] + nx * (s.pos[2] - 1)

    # Indices for visited vertices and edges
    # this creates a binary number where each bit corresponds to an element in s.visited_vertices.
    vertex_index = foldl((acc, b) -> 2 * acc + b, s.visited_vertices, init=0)
    # this creates a binary number where each bit corresponds to an element in s.visited_edges.
    edge_index = foldl((acc, b) -> 2 * acc + b, s.visited_edges, init=0)

    num_vertex_states = 2^MaxVertices
    num_edge_states = 2^MaxEdges

    # Combine indices to get a unique state index
    index = pos_index +
            nx * ny * vertex_index +
            nx * ny * num_vertex_states * edge_index

    return index + 1
end


function state_from_index(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}, index::Int) where {MaxVertices, MaxEdges}
    if index == length(pomdp)
        return pomdp.terminal_state
    end

    index -= 1  # Adjust for 1-based indexing
    nx, ny = pomdp.grid_size

    num_positions = nx * ny
    num_vertex_states = 2^MaxVertices
    num_edge_states = 2^MaxEdges

    # Extract edge index
    edge_index = div(index, num_positions * num_vertex_states)
    index %= num_positions * num_vertex_states

    # Extract vertex index
    vertex_index = div(index, num_positions)
    pos_index = index % num_positions

    # Reconstruct agent's position
    x = (pos_index % nx) + 1
    y = div(pos_index, nx) + 1
    pos = GraphPos(x, y)

    # Reconstruct visited vertices and edges
    visited_vertices = SVector{MaxVertices, Bool}([Bool((vertex_index >> i) & 1) for i in 0:MaxVertices-1])
    visited_edges = SVector{MaxEdges, Bool}([Bool((edge_index >> i) & 1) for i in 0:MaxEdges-1])

    return GraphState{MaxVertices, MaxEdges}(pos, visited_vertices, visited_edges)
end

# the state space is the pomdp itself
POMDPs.states(pomdp::GraphExplorationPOMDP) = pomdp

# Calculates the total number of states
function Base.length(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}) where {MaxVertices, MaxEdges}
    nx, ny = pomdp.grid_size
    num_positions = nx * ny
    num_vertex_states = 2^MaxVertices
    num_edge_states = 2^MaxEdges
    return num_positions * num_vertex_states * num_edge_states + 1  # +1 for terminal state
end

# we define an iterator over the state space
function Base.iterate(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}, i::Int=1) where {MaxVertices, MaxEdges}
    if i > length(pomdp)
        return nothing
    end
    s = state_from_index(pomdp, i)
    return (s, i+1)
end
