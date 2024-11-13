# +1 for visiting a new vertex or edge.
# -1 for revisiting a vertex or edge.
# +10 for completing the exploration.
include("observations.jl")
# using .observations: find_vertex_at_position, find_edge_at_position

function POMDPs.reward(pomdp::GraphExplorationPOMDP, s::GraphState, a::GraphAction)
    # Apply the action to get the new position
    new_pos = apply_action(s.pos, a, pomdp.grid_size)
    
    # Initialize reward
    reward = 0

    # Copy the visited statuses from the current state
    visited_vertices = s.visited_vertices
    visited_edges = s.visited_edges

    # Check if there's a vertex at the new position
    v_id = find_vertex_at_position(new_pos, pomdp.position_to_vertex)
    if v_id !== nothing
        if !s.visited_vertices[v_id]
            reward += 1  # Visiting a new vertex for the first time
            visited_vertices = Base.setindex(visited_vertices, true, v_id)
        else
            reward -= 1  # Revisiting a vertex
        end
    end

    # Check if there's an edge at the new position
    e_id = find_edge_at_position(new_pos, pomdp.position_to_edge)
    if e_id !== nothing
        if !s.visited_edges[e_id]
            reward += 1  # Visiting a new edge for the first time
            visited_edges = Base.setindex(visited_edges, true, e_id)
        else
            reward -= 1  # Revisiting an edge
        end
    end

    # Check if discovered graph matches the hidden graph
    hidden_vertices = Set(keys(pomdp.position_to_vertex))  # All hidden vertex positions
    hidden_edges = Set(keys(pomdp.position_to_edge))       # All hidden edge positions and directions
    
    # Check if discovered matches hidden
    # Map visited IDs back to positions
    vertex_id_to_pos = Dict(v => pos for (pos, v) in pomdp.position_to_vertex)
    edge_id_to_pos_dir = Dict(e => pos_dir for (pos_dir, e) in pomdp.position_to_edge)

    # Convert discovered IDs to positions
    discovered_vertices = Set(vertex_id_to_pos[v] for (v, visited) in enumerate(visited_vertices) if visited)
    discovered_edges = Set(edge_id_to_pos_dir[e] for (e, visited) in enumerate(visited_edges) if visited)

    if discovered_vertices == hidden_vertices && discovered_edges == hidden_edges
        reward += 10  # Completing exploration of the entire graph
    end

    return reward
end