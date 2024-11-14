using Random
using POMDPs
using POMDPTools
using Test
include("../src/GraphExploration.jl")
using .GraphExploration

@testset "GraphExplorationPOMDP Tests" begin

    # Define a simple POMDP instance
    pomdp = GraphExplorationPOMDP(
        grid_size = (3, 3),
        position_to_vertex = Dict(GraphPos(2, 2) => 1),
        position_to_edge = Dict((GraphPos(2, 2), :right) => 1),
        init_pos = GraphPos(1, 1),
        discount_factor = 0.95
    )
    
    # Test initial state
    @testset "initial state" begin
        s = initialstate(pomdp)
        @test s.pos == pomdp.init_pos
        @test all(!visited for visited in s.visited_vertices)
        @test all(!visited for visited in s.visited_edges)
    end
    
    # Test state space
    @testset "state space" begin
        ss = ordered_states(pomdp)
        @test length(ss) == length(pomdp)
        for (i, s) in enumerate(ss)
            @test stateindex(pomdp, s) == i
            @test state_from_index(pomdp, i) == s
        end
    end
    
    # Test actions
    @testset "actions" begin
        acts = actions(pomdp)
        @test length(acts) > 0
        @test acts == ordered_actions(pomdp)
    end
    
    # Test observations
    @testset "observations" begin
        obs = observations(pomdp)
        @test length(obs) > 0
        @test obs == ordered_observations(pomdp)
    end
    
    # Test reward function
    @testset "reward" begin
        s = initialstate(pomdp)
        a = :right  # Replace with a valid action
        r = reward(pomdp, s, a)
        # Replace `expected_reward_value` with the expected value from your reward function
        expected_reward_value = 0  # Adjust based on your implementation
        @test r == expected_reward_value
    end
    
    # Test transition function
    @testset "transition" begin
        s = initialstate(pomdp)
        a = :right  # Replace with a valid action
        sp_dist = transition(pomdp, s, a)
        sp = rand(sp_dist)
        # Test properties of sp
        # Adjust assertions based on your transition logic
    end
    
    # Test simulation
    @testset "simulation" begin
        rng = MersenneTwister(42)
        policy = RandomPolicy(pomdp, rng=rng)
        sim = HistoryRecorder(max_steps=10, rng=rng)
        simulate(sim, pomdp, policy)
        hist = POMDPTools.history(sim)
        @test n_steps(hist) > 0
    end
    
    # Test rendering (if applicable)
    @testset "rendering" begin
        s = initialstate(pomdp)
        render(pomdp, (s=s, a=:right))  # Replace with valid action
    end
    
    # Test constructor
    @testset "constructor" begin
        @test pomdp isa GraphExplorationPOMDP
        @test length(pomdp.position_to_vertex) == 1
        @test length(pomdp.position_to_edge) == 1
    end

end