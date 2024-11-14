# specifies what the agent observes after taking an action and transitioning to a new state.
# The observations are deterministic in this model.

# The file also includes helper functions to find vertices and edges at a given position.


# observation function
# Observations based on action and state transition
function POMDPs.observation(pomdp::GraphExplorationPOMDP, a::GraphAction, s::GraphState, sp::GraphState)
    return Deterministic(observation_from_state(pomdp, sp))
end

# Define obsindex to map each observation to a unique index
function POMDPs.obsindex(pomdp::GraphExplorationPOMDP, obs::GraphObservation)
    # Get all possible observations
    all_obs = POMDPs.observations(pomdp)

    # Find the index of the given observation
    index = findfirst(x -> x == obs, all_obs)

    if index === nothing
        error("Observation $obs is not valid for this POMDP.")
    end

    return index
end

# Observations based on state only (for belief sampling or debugging)
function POMDPs.observation(pomdp::GraphExplorationPOMDP, s::GraphState)
    return Deterministic(observation_from_state(pomdp, s))
end

function POMDPs.observations(pomdp::GraphExplorationPOMDP)
    # Enumerate all possible observations
    vertices = [nothing; collect(1:length(pomdp.position_to_vertex))]
    edges = [nothing; collect(1:length(pomdp.position_to_edge))]

    # Create all combinations of vertex and edge observations
    return [GraphObservation(v, e) for v in vertices for e in edges]
end

# Helper function to get observation from state
function observation_from_state(pomdp::GraphExplorationPOMDP, s::GraphState)
    v = find_vertex_at_position(s.pos, pomdp.position_to_vertex)
    e = find_edge_at_position(s.pos, pomdp.position_to_edge)
    return GraphObservation(v, e)
end

# find_vertex_at_position function
function find_vertex_at_position(pos::GraphPos, position_to_vertex::Dict{GraphPos, Int})
    return get(position_to_vertex, pos, nothing)
end

# find_edge_at_position function
function find_edge_at_position(pos::GraphPos, position_to_edge::Dict{Tuple{GraphPos, Symbol}, Int})
    for ((edge_pos, _), edge_id) in position_to_edge
        if edge_pos == pos
            return edge_id
        end
    end
    return nothing  # Return `nothing` if no edge matches the position
end