using Random
# using GraphExploration
using POMDPs
using POMDPTools
using Test
using Compose
using SARSOP
using POMDPGifs
include("../src/GraphExploration.jl")
using .GraphExploration
import Cairo, Fontconfig
using Distributions


# Set the width and height globally
const w = 800  # Width in pixels
const h = 600  # Height in pixels

using POMDPPolicies
using POMDPSimulators

using Distributions

using Distributions
using Random

# Extend Random.Sampler for Deterministic distributions
function Random.Sampler(::Type{<:AbstractRNG}, d::Deterministic{T}, ::Val{1}) where {T}
    return Random.SamplerTrivial(d.val)  # Use `val` field
end

# Extend rand for SamplerTrivial
function Base.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{T}) where {T}
    return sampler.self  # Use `self
end

# Function to test the transition function
function test_transition_function()
    println("Testing Transition Function...")
    # Create a small POMDP instance
    pomdp = GraphExplorationPOMDP(
        grid_size = (3, 3),
        position_to_vertex = Dict(GraphPos(2, 2) => 1),
        position_to_edge = Dict((GraphPos(2, 1), :up) => 1),
        init_pos = GraphPos(1, 1),
        discount_factor = 0.95
    )

    s = initialstate(pomdp)
    a = :right

    sp_dist = POMDPs.transition(pomdp, s, a)
    sp = rand(sp_dist)

    # Expected new position is (2, 1)
    expected_pos = GraphPos(2, 1)
    @test sp.pos == expected_pos

    # Since there's no vertex at (2,1), visited statuses should remain the same
    @test sp.visited_vertices == s.visited_vertices
    # Check visited edges: the edge at (2, 1) should now be visited
    updated_edges = Base.setindex(s.visited_edges, true, 1)  # Edge ID 1 is now visited
    @test sp.visited_edges == updated_edges

    println("Transition Function test passed.")
end

# Function to test the observation function
function test_observation_function()
    println("Testing Observation Function...")
    # Create a small POMDP instance
    pomdp = GraphExplorationPOMDP(
        grid_size = (3, 3),
        position_to_vertex = Dict(GraphPos(2, 2) => 1),
        position_to_edge = Dict((GraphPos(2, 1), :up) => 1),
        init_pos = GraphPos(1, 1),
        discount_factor = 0.95
    )

    # Move to position without vertex or edge
    s = initialstate(pomdp)
    a = :up
    sp = rand(POMDPs.transition(pomdp, s, a))
    o = rand(POMDPs.observation(pomdp, a, s, sp))

    expected_obs = GraphObservation(nothing, nothing)
    @test o.vertex == expected_obs.vertex
    @test o.edge == expected_obs.edge

    # Move to position with a vertex
    s = sp
    a = :right
    sp = rand(POMDPs.transition(pomdp, s, a))
    o = rand(POMDPs.observation(pomdp, a, s, sp))

    expected_obs = GraphObservation(1, nothing)
    @test o.vertex == expected_obs.vertex
    @test o.edge == expected_obs.edge

    println("Observation Function test passed.")
end

# Function to test the reward function
function test_reward_function()
    println("Testing Reward Function...")
    # Create a small POMDP instance
    pomdp = GraphExplorationPOMDP(
        grid_size = (4, 4),
        position_to_vertex = Dict(GraphPos(2, 2) => 1,
                                GraphPos(2, 4) => 2,),
        position_to_edge = Dict{Tuple{GraphPos, Symbol}, Int}(), 
        init_pos = GraphPos(1, 1),
        discount_factor = 0.95
    )

    s = initialstate(pomdp)

    # Move to empty cell
    a = :right
    r = POMDPs.reward(pomdp, s, a)
    @test r == 0

    # Move to cell with vertex
    s = rand(POMDPs.transition(pomdp, s, a))
    a = :up
    r = POMDPs.reward(pomdp, s, a)
    @test r == 1  # Visiting new vertex

    # Revisit the same vertex
    s = rand(POMDPs.transition(pomdp, s, a))
    a = :down
    s = rand(POMDPs.transition(pomdp, s, a))
    a = :up
    r = POMDPs.reward(pomdp, s, a)
    @test r == -1  # Revisiting vertex

    println("Reward Function test passed.")
end
function POMDPs.actions(pomdp::GraphExplorationPOMDP, s::GraphState)
    println("Available actions: ", [action for action in MOVEMENT_ACTIONS])
    return MOVEMENT_ACTIONS
end
# Function to test simulation with a random policy
function test_simulation()
    println("Testing Simulation...")
    pomdp = GraphExplorationPOMDP(
        grid_size = (2, 2),
        position_to_vertex = Dict(GraphPos(1, 2) => 1),
        position_to_edge = Dict{Tuple{GraphPos, Symbol}, Int}(), 
        init_pos = GraphPos(1, 1),
        discount_factor = 0.95
    )
    s = initialstate(pomdp)
    s = initialstate(pomdp)
    a = :right
    sp_dist = POMDPs.transition(pomdp, s, a)
    println("Sampled next state: ", rand(sp_dist))
    
    policy = RandomPolicy(pomdp)
     # Create a random number generator
     rng = Random.TaskLocalRNG()

     # Use `stepthrough` to simulate the process
    sim = stepthrough(pomdp, policy, "s,a,o,r,sp", rng=rng, max_steps=10)
 
     # Iterate through the simulation manually
     for (i, step) in enumerate(sim)
        s = step[:s]   # Current state
        a = step[:a]   # Action taken
        o = step[:o]   # Observation received
        r = step[:r]   # Reward received
        sp = step[:sp] # Next state
         println("Step $i: s=$(s.pos), a=$a, o=$o, r=$r, sp=$(sp.pos)")
     end

    println("Simulation test passed.")
end

# Function to test compatibility with SARSOP solver
function test_sarsop_solver()
    println("Testing SARSOP Solver...")
    # Create a small POMDP instance
    pomdp = GraphExplorationPOMDP(
        grid_size = (2, 2),
        position_to_vertex = Dict(GraphPos(1, 1) => 1),
        position_to_edge = Dict{Tuple{GraphPos, Symbol}, Int}(), 
        init_pos = GraphPos(1, 1),
        discount_factor = 0.95
    )
    for (i, state) in enumerate(POMDPs.states(pomdp))
        println("State $i: ", state)
    end

    # Ensure observations are defined
    observations(pomdp)

    # Create a SARSOP solver instance
    solver = SARSOPSolver(precision=1.0, timeout=10.0)

    # Solve the POMDP
    policy = solve(solver, pomdp)

    # Simulate with the policy
    sim = HistoryRecorder(max_steps=10)
    
    simulate(sim, pomdp, policy)

    recorded_history = POMDPTools.history(sim)

    for (i, step) in enumerate(recorded_history)
        s = step.s
        a = step.a
        o = step.o
        r = step.r
        sp = step.sp

        println("Step $i: s=$(s.pos), a=$a, o=$o, r=$r, sp=$(sp.pos)")
    end

    println("SARSOP Solver test passed.")
end

# Run the tests
test_transition_function()
test_observation_function()
test_reward_function()
test_simulation()
test_sarsop_solver()


# Test function for visualization
function test_initial_state()
    # Create a sample POMDP instance
    pomdp = GraphExplorationPOMDP(
        grid_size = (5, 5),
        position_to_vertex = Dict(GraphPos(2, 2) => 1, GraphPos(4, 2) => 2, GraphPos(4, 4) => 3),
        position_to_edge = Dict(
            (GraphPos(3, 2), :right) => 1,
            (GraphPos(4, 3), :up) => 2,
        ),
        init_pos = GraphPos(1, 1),
        discount_factor = 0.95
    )
    
    # Get the initial state
    s0 = initialstate(pomdp)

    # Define a step with a state and an action
    step = (s = s0, a = :right)

    # Call the render function
    c = POMDPTools.render(pomdp, step)

    # Save the visualization as PNG
    c |> PNG("graphexploration_initial.png", w, h)
    println("Visualization saved to graphexploration_initial.png")
end

function test_simulation_steps()
    # Create a sample POMDP instance
    # pomdp = GraphExplorationPOMDP(
    #     grid_size = (5, 5),
    #     position_to_vertex = Dict(GraphPos(2, 2) => 1, GraphPos(4, 2) => 2, GraphPos(4, 4) => 3),
    #     position_to_edge = Dict(
    #         (GraphPos(3, 2), :right) => 1,
    #         (GraphPos(4, 3), :up) => 2,
    #     ),
    #     init_pos = GraphPos(1, 1),
    #     discount_factor = 0.95
    # )

    pomdp = GraphExplorationPOMDP(
    grid_size = (5, 5),  # A 5x5 grid
    position_to_vertex = Dict(
        GraphPos(2, 2) => 1,
        GraphPos(2, 4) => 2,
        GraphPos(4, 2) => 3,
        GraphPos(4, 4) => 4
    ),
    position_to_edge = Dict(
        (GraphPos(2, 3), :up) => 1,     # Edge 1 connects Vertex 1 to Vertex 2
        (GraphPos(3, 2), :right) => 2,  # Edge 2 connects Vertex 1 to Vertex 3
        (GraphPos(3, 4), :left) => 3,   # Edge 3 connects Vertex 2 to Vertex 4
        (GraphPos(4, 3), :down) => 4    # Edge 4 connects Vertex 3 to Vertex 4
    ),
    init_pos = GraphPos(1, 1),  # Starting position
    discount_factor = 0.95
)
    # Initialize state
    s = initialstate(pomdp)
    total_reward = 0.0

    # Define a sequence of actions to test
    actions = [:up, :right, :right, :right, :up, :up, :left, :left, :down]

    # Simulate each step
    for (t, a) in enumerate(actions)
        println("Step $t:")
        println("Action: $a")
        
        # Get the next state (unwrap Deterministic to extract state)
        sp_dist = POMDPs.transition(pomdp, s, a)
        sp = rand(sp_dist)  # Extract state from Deterministic distribution

        # Get the reward
        r = POMDPs.reward(pomdp, s, a)
        total_reward += r

        # Visualize the current step
        step = (s = s, a = a)
        c = POMDPTools.render(pomdp, step)
        c |> PNG("graphexploration_step_$t.png", w, h)
        println("Visualization saved to graphexploration_step_$t.png")
        println("Reward: $r")
        println("Total Reward: $total_reward")
        println("-------")

        println("Checking if the making this action is terminal")
        if POMDPs.isterminal(pomdp, sp)
            println("Reached terminal state.")
            break
        end

        # Update the state
        s = sp

        
    end
end

function test_solver()
    pomdp = GraphExplorationPOMDP(
        grid_size = (5, 5),  # A 5x5 grid
        position_to_vertex = Dict(
            GraphPos(2, 2) => 1,
            GraphPos(2, 4) => 2,
            GraphPos(4, 2) => 3,
            GraphPos(4, 4) => 4
        ),
        position_to_edge = Dict(
            (GraphPos(2, 3), :up) => 1,     # Edge 1 connects Vertex 1 to Vertex 2
            (GraphPos(3, 2), :right) => 2,  # Edge 2 connects Vertex 1 to Vertex 3
            (GraphPos(3, 4), :left) => 3,   # Edge 3 connects Vertex 2 to Vertex 4
            (GraphPos(4, 3), :down) => 4    # Edge 4 connects Vertex 3 to Vertex 4
        ),
        init_pos = GraphPos(1, 1),  # Starting position
        discount_factor = 0.95
    )
    solver = SARSOPSolver(precision=1e-3)

    policy = solve(solver, pomdp)

    sim = GifSimulator(filename="test.gif", max_steps=30)
    simulate(sim, pomdp, policy)
end

# test_solver()