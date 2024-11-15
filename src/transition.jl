# This file defines the state transition dynamics of the GraphExplorationPOMDP.
# It specifies how the state changes in response to an action.
# The transitions are deterministic in this model.
include("observations.jl")
# using .observations: find_vertex_at_position, find_edge_at_position

# Define the transition function as per the POMDPs.jl interface.
function POMDPs.transition(pomdp::GraphExplorationPOMDP{MaxVertices, MaxEdges}, s::GraphState{MaxVertices, MaxEdges}, a::GraphAction) where {MaxVertices, MaxEdges}
    if POMDPs.isterminal(pomdp, s)
        return Deterministic(pomdp.terminal_state)
    end

    # Compute new position based on action
    new_pos = apply_action(s.pos, a, pomdp.grid_size)

    # Clamp new position to grid bounds
    nx, ny = pomdp.grid_size
    x_new, y_new = new_pos
    x_new = clamp(x_new, 1, nx)
    y_new = clamp(y_new, 1, ny)
    new_pos = GraphPos(x_new, y_new)

    # Copy visited statuses
    visited_vertices = s.visited_vertices
    visited_edges = s.visited_edges

    # Update visited vertices
    v_id = find_vertex_at_position(new_pos, pomdp.position_to_vertex)
    if v_id !== nothing
        if !visited_vertices[v_id]
            visited_vertices = Base.setindex(visited_vertices, true, v_id)
        end
    end

    # Update visited edges
    e_id = find_edge_at_position(new_pos, pomdp.position_to_edge)
    if e_id !== nothing
        if !visited_edges[e_id]
            visited_edges = Base.setindex(visited_edges, true, e_id)
        end
    end

    # Construct the new state
    new_state = GraphState{MaxVertices, MaxEdges}(new_pos, visited_vertices, visited_edges)

    # Check if the new state is terminal
    if POMDPs.isterminal(pomdp, new_state)
        return Deterministic(pomdp.terminal_state)
    else
        println("testing transition" + Deterministic(new_state))
        return Deterministic(new_state)
    end
end

# Compute the new position based on the action.
function apply_action(pos::GraphPos, a::GraphAction, grid_size::Tuple{Int, Int})
    x, y = pos[1], pos[2]
    nx, ny = grid_size
    if a == :up
        new_pos = GraphPos(x, y + 1)
    elseif a == :down
        new_pos = GraphPos(x, y - 1)
    elseif a == :left
        new_pos = GraphPos(x - 1, y)
    elseif a == :right
        new_pos = GraphPos(x + 1, y)
    elseif a isa Tuple{Int, Int}
        x_new, y_new = a
        new_pos = GraphPos(x_new, y_new)
    else
        # Invalid action; stay in the same position
        new_pos = pos
    end
    return new_pos
end