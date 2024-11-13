# using Compose
# using POMDPs
# using POMDPTools
# using .GraphExploration



# Function to render the POMDP state and action
function POMDPTools.render(pomdp::GraphExplorationPOMDP, step;
    pre_act_text="")
    # Grid dimensions
    nx, ny = pomdp.grid_size[1] + 1, pomdp.grid_size[2] + 1
    cells = []

    # Draw grid cells
    for x in 1:nx-1, y in 1:ny-1
        ctx = cell_ctx((x, y), (nx, ny))
        cell = compose(ctx, rectangle(), fill("white"))
        push!(cells, cell)
    end

    grid = compose(context(), linewidth(0.5mm), stroke("gray"), cells...)
    outline = compose(context(), linewidth(1mm), rectangle())
    

    # Draw vertices
    vertices = []
    for (pos, v_id) in pomdp.position_to_vertex
        print("Vertex ID: ", v_id)
        ctx = cell_ctx((pos[1], pos[2]), (nx, ny))
        clr = "blue"
        if get(step, :s, nothing) !== nothing && step[:s].visited_vertices[v_id]
            clr = "green"
        end
        vertex = compose(ctx, circle(0.5, 0.5, 0.3), fill(clr), stroke("black"))
        push!(vertices, vertex)
    end
    vertices = compose(context(), vertices...)
    

    # Draw edges
    edges = []
    for (pos, e_id) in pomdp.position_to_edge
        # print("Edge ID: ", e_id)
        ctx = cell_ctx((pos[1], pos[2]), (nx, ny))
        clr = "orange"
        if get(step, :s, nothing) !== nothing && step[:s].visited_edges[e_id]
            clr = "green"
        end
        edge = compose(ctx, rectangle(0.2, 0.2, 0.6, 0.6), fill(clr), stroke("black"))
        push!(edges, edge)
    end
    edges = compose(context(), edges...)
    
    # Draw agent
    agent = nothing
    action = nothing
    # print("Agent position: ", get(step, :s, nothing))
    if get(step, :s, nothing) !== nothing
        # print("Agent position: ", step[:s].pos)
        agent_ctx = cell_ctx((step[:s].pos[1], step[:s].pos[2]), (nx, ny))
        agent = render_agent(agent_ctx)
        if get(step, :a, nothing) !== nothing
            action = render_action(pomdp, step)
        end
    end

    # Action text
    action_text = render_action_text(pomdp, step, pre_act_text)

    # Compose the final image
    sz = min(w, h)
    return compose(context((w - sz) / 2, (h - sz) / 2, sz, sz),
                #    grid, outline, vertices, edges, agent, action_text)
                agent, vertices, edges, action_text, grid, outline)
end

# Helper function to create a cell context
function cell_ctx(xy, size)
    nx, ny = size
    x, y = xy
    return context((x - 1) / nx, (ny - y) / ny, 1 / nx, 1 / ny)
end

# Function to render the agent at its position
function render_agent(ctx)
    return compose(ctx, circle(0.5, 0.5, 0.3), fill("red"), stroke("black"))
end

# Renders the action performed by the agent.
function render_action(pomdp::GraphExplorationPOMDP, step)
    nx, ny = pomdp.grid_size[1] + 1, pomdp.grid_size[2] + 1
    pos = step.s.pos  # Agent's current position
    ctx = cell_ctx(pos, (nx, ny))

    if step.a in [:up, :down, :left, :right]
        # Movement actions
        arrow = step.a == :up    ? [(0.5, 0.7), (0.5, 1.0)]  :  # Arrow pointing up
                step.a == :down  ? [(0.5, 0.3), (0.5, 0.0)]  :  # Arrow pointing down
                step.a == :left  ? [(0.3, 0.5), (0.0, 0.5)]  :  # Arrow pointing left
                                  [(0.7, 0.5), (1.0, 0.5)]      # Arrow pointing right
        return compose(ctx, line(arrow), stroke("blue"), linewidth(0.01))
    elseif step.a isa Tuple{Int, Int}
        # Teleportation action
        target_pos = step.a
        target_ctx = cell_ctx(target_pos, (nx, ny))
        return compose(context(), line([ctx, target_ctx]), stroke("green"), linewidth(0.01))
    else
        return nothing  # No action visualization
    end
end
# Function to render the action text
function render_action_text(pomdp::GraphExplorationPOMDP, step, pre_act_text)
    action_text = "Terminal"
    # println("Agent position: ", get(step, :a, nothing))
    if get(step, :a, nothing) !== nothing
        a = step[:a]
        if a isa Symbol
            action_text = string(pre_act_text, a)
        elseif a isa Tuple{Int, Int}
            action_text = string(pre_act_text, "Teleport to ", a)
        else
            action_text = string(pre_act_text, "Unknown Action")
        end
    end

    _, ny = pomdp.grid_size
    ny += 1
    ctx = context(0, 0, 1, 1 / ny)  # Context for the top area
    txt = compose(context(0, 0, 1, 1), text(0.5, 0.5, action_text, hcenter, vcenter),
        stroke("black"),
        fill("black"),
        fontsize(100pt))
    return compose(ctx, rectangle(), fill("white"), txt)
end