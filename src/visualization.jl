# using Compose
# using POMDPs
# using POMDPTools
# using .GraphExploration



# Function to render the POMDP state and action
function POMDPTools.render(pomdp::GraphExplorationPOMDP, step; pre_act_text="")
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
        ctx = cell_ctx((pos[1], pos[2]), (nx, ny))
        clr = "blue"
        if get(step, :s, nothing) !== nothing && step[:s].visited_vertices[v_id]
            clr = "green"
        end
        vertex = compose(ctx, circle(0.5, 0.5, 0.3), fill(clr), stroke("black"))
        push!(vertices, vertex)
    end
    vertices = compose(context(), vertices...)

    # Draw edges with directions
    edges = render_edges(pomdp, step, (nx, ny))

    # Draw agent
    agent = nothing
    if get(step, :s, nothing) !== nothing
        agent_ctx = cell_ctx((step[:s].pos[1], step[:s].pos[2]), (nx, ny))
        agent = render_agent(agent_ctx)
    end

    # Action text
    action_text = render_action_text(pomdp, step, pre_act_text)

    # Compose the final image
    sz = min(w, h)
    return compose(context((w - sz) / 2, (h - sz) / 2, sz, sz),
                  vertices, edges, agent, action_text,  grid, outline)
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

# Function to render the action text
function render_action_text(pomdp::GraphExplorationPOMDP, step, pre_act_text)
    action_text = "Terminal"
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

# Predefined triangle shapes for each direction
function triangle_shapes(size=0.1)
    up_triangle = [(0.5, 0.5 - size), (0.5 - size, 0.5 + size), (0.5 + size, 0.5 + size)]
    down_triangle = [(0.5, 0.5 + size), (0.5 - size, 0.5 - size), (0.5 + size, 0.5 - size)]
    left_triangle = [(0.5 - size, 0.5), (0.5 + size, 0.5 - size), (0.5 + size, 0.5 + size)]
    right_triangle = [(0.5 + size, 0.5), (0.5 - size, 0.5 - size), (0.5 - size, 0.5 + size)]
    return Dict(:up => up_triangle, :down => down_triangle, :left => left_triangle, :right => right_triangle)
end

# Function to render edges with triangles
function render_edges(pomdp::GraphExplorationPOMDP, step, grid_size)
    nx, ny = grid_size[1], grid_size[2]
    edges = []
    triangles = triangle_shapes(0.15)  # Adjust size as needed

    for ((pos, direction), e_id) in pomdp.position_to_edge
        # Get the triangle for the specified direction
        triangle = triangles[direction]

        # Position the triangle at the appropriate grid cell
        ctx = cell_ctx((pos[1], pos[2]), (nx, ny))

        # Determine the color of the triangle
        clr = "orange"
        if get(step, :s, nothing) !== nothing && step[:s].visited_edges[e_id]
            clr = "green"
        end

        # Render the triangle
        edge = compose(ctx, polygon(triangle), fill(clr), stroke("black"))
        push!(edges, edge)
    end

    return compose(context(), edges...)
end