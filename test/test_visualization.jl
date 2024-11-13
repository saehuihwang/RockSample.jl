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
        position_to_vertex = Dict(GraphPos(2, 2) => 1, GraphPos(3, 3) => 2, GraphPos(4, 4) => 3),
        position_to_edge = Dict(GraphPos(2, 3) => 1, GraphPos(3, 2) => 2),
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

test_initial_state()