# Define GraphObservation
struct GraphObservation
    vertex::Union{Int, Nothing}               # Vertex ID or nothing
    edge::Union{Int, Nothing}                 # Edge ID or nothing
end
# observation function
function POMDPs.observation(pomdp::GraphExplorationPOMDP, a::GraphAction, s::GraphState, sp::GraphState)
    # Observation depends on the new state sp
    obs = observation_from_state(pomdp, sp)
    return Deterministic(obs)
end

# Helper function to get observation from state
function observation_from_state(pomdp::GraphExplorationPOMDP, s::GraphState)
    v = find_vertex_at_position(s.pos, pomdp.position_to_vertex)
    e = find_edge_at_position(s.pos, pomdp.position_to_edge)
    return GraphObservation(v, e)
end

# find_vertex_at_position function
function find_vertex_at_position(pos::Tuple{Int, Int}, position_to_vertex::Dict{Tuple{Int, Int}, Int})
    return get(position_to_vertex, pos, nothing)
end

# find_edge_at_position function
function find_edge_at_position(pos::Tuple{Int, Int}, position_to_edge::Dict{Tuple{Int, Int}, Int})
    return get(position_to_edge, pos, nothing)
end