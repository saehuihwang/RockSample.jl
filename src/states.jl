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

function POMDPs.states(pomdp::GraphExplorationPOMDP)
    nx, ny = pomdp.grid_size
    positions = [(x, y) for x in 1:nx, y in 1:ny]

    # Determine all possible combinations of visited vertices and edges
    num_vertices = length(pomdp.position_to_vertex)
    num_edges = length(pomdp.position_to_edge)

    visited_vertices_combinations = Iterators.product([true, false] for _ in 1:num_vertices)
    visited_edges_combinations = Iterators.product([true, false] for _ in 1:num_edges)

    # Generate all valid states
    valid_states = []
    for pos in positions
        for visited_vertices in visited_vertices_combinations
            for visited_edges in visited_edges_combinations
                # Validate the state, ensuring empty cells are considered
                if is_valid_state(pomdp, pos, visited_vertices, visited_edges)
                    push!(valid_states, GraphState(pos, visited_vertices, visited_edges))
                end
            end
        end
    end

    return valid_states
end

# Helper function to validate a state
function is_valid_state(pomdp::GraphExplorationPOMDP, pos::Tuple{Int, Int}, visited_vertices, visited_edges)
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
