using Random
# using GraphExploration
using POMDPs
using POMDPTools
using Test
using Compose
include("../src/GraphExploration.jl")
using .GraphExploration
import Cairo, Fontconfig


# Set the width and height globally
const w = 800  # Width in pixels
const h = 600  # Height in pixels

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
    # Initialize state
    s = initialstate(pomdp)
    total_reward = 0.0

    # Define a sequence of actions to test
    actions = [:up, :right, :right, :right, :up, :up, :up, :up]

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


test_simulation_steps()