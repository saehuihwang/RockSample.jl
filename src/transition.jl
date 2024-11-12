# This file defines the state transition dynamics of the GraphExplorationPOMDP.
# It specifies how the state changes in response to an action.
# The transitions are deterministic in this model.
import ..observations: find_vertex_at_position, find_edge_at_position

# Define the transition function as per the POMDPs.jl interface.
function POMDPs.transition(pomdp::GraphExplorationPOMDP{NVertices, NEdges}, s::GraphState{NVertices, NEdges}, a::GraphAction) where {NVertices, NEdges}
    if POMDPs.isterminal(pomdp, s)
        return Deterministic(pomdp.terminal_state)
    end

    # Compute new position based on action
    new_pos = apply_action(s.pos, a, pomdp.grid_size)
    
    # Clamp new position to grid bounds. ensure new position is within grid
    nx, ny = pomdp.grid_size
    x_new, y_new = new_pos
    x_new = clamp(x_new, 1, nx)
    y_new = clamp(y_new, 1, ny)
    new_pos = GraphPos(x_new, y_new)
    
    # Copy visited statuses
    visited_vertices = s.visited_vertices
    visited_edges = s.visited_edges
    
    # Update visited vertices. check if there's vertex at new position. 
    v_id = find_vertex_at_position(new_pos, pomdp.position_to_vertex) # defined in observations.jl
     # if vertex hasn't been visited, update status to true
    if v_id !== nothing && !visited_vertices[v_id]
        visited_vertices = Base.setindex(visited_vertices, true, v_id)
    end

    # Update visited edges. check if there's edge at new position. 
    e_id = find_edge_at_position(new_pos, pomdp.position_to_edge) # defined in observations.jl
    # if edge hasn't been visited, update status to truw
    if e_id !== nothing && !visited_edges[e_id]
        visited_edges = Base.setindex(visited_edges, true, e_id)
    end

    # Constructs the new state with the updated position and visited statuses.
    new_state = GraphState{NVertices, NEdges}(new_pos, visited_vertices, visited_edges)

    # Check if the new state is terminal
    if POMDPs.isterminal(pomdp, new_state)
        return Deterministic(pomdp.terminal_state)
    else
        return Deterministic(new_state)
    end
end

# Compute the new position based on the action.
function apply_action(pos::GraphPos, a::GraphAction, grid_size::Tuple{Int, Int})
    x, y = pos
    nx, ny = grid_size
    if a == :up
        new_pos = (x, y + 1)
    elseif a == :down
        new_pos = (x, y - 1)
    elseif a == :left
        new_pos = (x - 1, y)
    elseif a == :right
        new_pos = (x + 1, y)
    elseif a isa Tuple{Int, Int}
        x_new, y_new = a
        new_pos = (x_new, y_new)
    else
        # Invalid action; stay in the same position
        new_pos = pos
    end
    return new_pos
end