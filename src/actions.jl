const MOVEMENT_ACTIONS = [:up, :down, :left, :right]

function generate_teleport_actions(grid_size::Tuple{Int, Int})
    nx, ny = grid_size
    return [(x, y) for x in 1:nx, y in 1:ny] |> vec
end

# movement actions and teleportation actions
function POMDPs.actions(pomdp::GraphExplorationPOMDP)
    teleport_actions = generate_teleport_actions(pomdp.grid_size)
    return Union{Symbol, Tuple{Int, Int}}[MOVEMENT_ACTIONS...; teleport_actions...]  # Ensure same type
end

# Maps an action to its index.
# Movement actions are indices 1 to 4.
# Teleportation actions are indices 5 to 4 + (nx * ny)
function POMDPs.actionindex(pomdp::GraphExplorationPOMDP, a)
    if a in MOVEMENT_ACTIONS
        return findfirst(isequal(a), MOVEMENT_ACTIONS)
    elseif a isa Tuple{Int, Int}
        nx, ny = pomdp.grid_size
        x, y = a
        # Validate position
        if x < 1 || x > nx || y < 1 || y > ny
            error("Invalid teleport action: position out of bounds.")
        end
        index = length(MOVEMENT_ACTIONS) + (x - 1) * ny + y
        return index
    else
        error("Invalid action.")
    end
end

# tells which actions are valid given a state
function POMDPs.actions(pomdp::GraphExplorationPOMDP, s::GraphState)
    nx, ny = pomdp.grid_size
    x, y = s.pos

    available_actions = []

    # Movement actions with bounds checking
    if y < ny
        push!(available_actions, :up)
    end
    if y > 1
        push!(available_actions, :down)
    end
    if x > 1
        push!(available_actions, :left)
    end
    if x < nx
        push!(available_actions, :right)
    end

    # Teleport actions (available at all times)
    teleport_actions = generate_teleport_actions(pomdp.grid_size)

    return vcat(available_actions, teleport_actions)
end

function POMDPs.actions(pomdp::GraphExplorationPOMDP, b)
    state = rand(Random.GLOBAL_RNG, b) 
    return actions(pomdp, state)
end