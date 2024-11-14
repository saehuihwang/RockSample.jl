# implementing required state-related functions for the POMDPs.jl framework
# such as state indexing, state reconstruction from indices, and state space iteration.

# Map a state to a unique index.
function POMDPs.stateindex(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}, s::GraphState{MaxVertices, MaxEdges}) where {MaxVertices, MaxEdges}
    if POMDPs.isterminal(pomdp, s)
        return length(pomdp)
    end
    nx, ny = pomdp.grid_size

    # Agent's position index (zero-based)
    pos_index = (s.pos[2] - 1) * nx + (s.pos[1] - 1)

    # Indices for visited vertices and edges
    vertex_index = 0
    for (i, visited) in enumerate(s.visited_vertices)
        vertex_index += visited << (i - 1)
    end

    edge_index = 0
    for (i, visited) in enumerate(s.visited_edges)
        edge_index += visited << (i - 1)
    end

    num_vertex_states = 2^MaxVertices
    num_edge_states = 2^MaxEdges
    num_positions = nx * ny

    # Combine indices to get a unique state index
    index = pos_index +
            num_positions * vertex_index +
            num_positions * num_vertex_states * edge_index

    return index + 1  # Convert to one-based indexing
end

function state_from_index(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}, index::Int) where {MaxVertices, MaxEdges}
    if index == length(pomdp)
        return pomdp.terminal_state
    end

    index -= 1  # Convert to zero-based indexing
    nx, ny = pomdp.grid_size

    num_positions = nx * ny
    num_vertex_states = 2^MaxVertices
    num_edge_states = 2^MaxEdges

    # Extract edge index
    edge_index = div(index, num_positions * num_vertex_states)
    index %= num_positions * num_vertex_states

    # Extract vertex index
    vertex_index = div(index, num_positions)
    index %= num_positions

    # Extract position index
    pos_index = index

    # Reconstruct agent's position
    x = (pos_index % nx) + 1
    y = div(pos_index, nx) + 1
    pos = GraphPos(x, y)

    # Reconstruct visited vertices and edges
    visited_vertices = ntuple(i -> Bool((vertex_index >> (i - 1)) & 1), MaxVertices)
    visited_edges = ntuple(i -> Bool((edge_index >> (i - 1)) & 1), MaxEdges)

    return GraphState{MaxVertices, MaxEdges}(pos, SVector{MaxVertices, Bool}(visited_vertices...), SVector{MaxEdges, Bool}(visited_edges...))
end

function POMDPs.states(pomdp::GraphExplorationPOMDP)
    nx, ny = pomdp.grid_size
    positions = [GraphPos(x, y) for y in 1:ny, x in 1:nx] |> vec

    num_vertices = length(pomdp.position_to_vertex)
    num_edges = length(pomdp.position_to_edge)

    visited_vertices_combinations = Iterators.product([false, true] for _ in 1:num_vertices)
    visited_edges_combinations = Iterators.product([false, true] for _ in 1:num_edges)

    valid_states = []
    for pos in positions
        for visited_vertices in visited_vertices_combinations
            for visited_edges in visited_edges_combinations
                push!(valid_states, GraphState(pos, SVector{num_vertices, Bool}(visited_vertices), SVector{num_edges, Bool}(visited_edges)))
            end
        end
    end

    # Add terminal state
    push!(valid_states, pomdp.terminal_state)

    return valid_states
end

# Helper function to validate a state
function is_valid_state(pomdp::GraphExplorationPOMDP, pos::GraphPos, visited_vertices, visited_edges)
    v_id = find_vertex_at_position(pos, pomdp.position_to_vertex)
    e_id = find_edge_at_position(pos, pomdp.position_to_edge)

    # If the cell is neither a vertex nor an edge, it's valid
    if v_id === nothing && e_id === nothing
        return true
    end

    # If the cell is a vertex, it cannot also be an edge
    if v_id !== nothing && e_id !== nothing
        return false
    end

    return true
end

function Base.length(pomdp::GraphExplorationPOMDP)
    return length(POMDPs.states(pomdp))
end

function Base.iterate(pomdp::GraphExplorationPOMDP, i::Int=1)
    states = POMDPs.states(pomdp)
    if i > length(states)
        return nothing
    end
    return (states[i], i + 1)
end
