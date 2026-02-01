# Road rendering system
class RoadRenderer
  def initialize(camera)
    @camera = camera
    # Cache road surface geometry since it never changes
    @cached_road_surface = generate_road_surface_geometry
    @cached_road_edges = generate_road_edges_geometry
  end

  def render(args, distance, player_speed = Config::PLAYER_START_SPEED)
    draw_road_surface(args)
    draw_lane_dividers(args, distance, player_speed)
    draw_road_edges(args)
  end

  private

  def draw_road_surface(args)
    # Use cached road surface geometry (never changes)
    args.outputs.sprites << @cached_road_surface
  end

  def generate_road_surface_geometry
    # Generate the road surface geometry once at initialization
    # Near edge (bottom of screen, close to player)
    near_left = @camera.world_to_screen(Config::ROAD_MIN_X, 0)
    near_right = @camera.world_to_screen(Config::ROAD_MAX_X, 0)

    # Far edge (vanishing point)
    far_left = @camera.world_to_screen(Config::ROAD_MIN_X, @camera.world_depth)
    far_right = @camera.world_to_screen(Config::ROAD_MAX_X, @camera.world_depth)

    # Calculate total height of road on screen
    road_height = far_left[:y] - near_left[:y]

    # Generate road as a solid trapezoid using horizontal lines
    # Use enough lines to fill completely without gaps
    road_lines = []
    num_lines = (road_height / 2).ceil  # One line every 2 pixels
    num_lines.times do |i|
      t = i.to_f / num_lines

      y = near_left[:y] + (far_left[:y] - near_left[:y]) * t
      left_x = near_left[:x] + (far_left[:x] - near_left[:x]) * t
      right_x = near_right[:x] + (far_right[:x] - near_right[:x]) * t

      road_lines << {
        x: left_x,
        y: y,
        w: right_x - left_x,
        h: 3,  # Slightly overlapping to ensure no gaps
        path: :pixel,
        r: Config::ROAD_COLOR[:r],
        g: Config::ROAD_COLOR[:g],
        b: Config::ROAD_COLOR[:b]
      }
    end

    road_lines
  end

  def draw_lane_dividers(args, distance, player_speed)
    # Draw lane dividers between lanes
    # Scale divider spacing based on player speed to create sense of velocity
    # Faster speed = smaller spacing = faster dashing effect
    base_spacing = Config::LANE_DIVIDER_SPACING
    base_speed = Config::PLAYER_START_SPEED

    # Calculate speed multiplier (how much faster than base speed)
    speed_multiplier = player_speed / base_speed.to_f
    speed_multiplier = [speed_multiplier, 0.5].max  # Don't go below 50% spacing

    # Reduce spacing as speed increases
    divider_spacing = (base_spacing / speed_multiplier).to_i
    divider_spacing = [divider_spacing, 30].max  # Minimum spacing to prevent visual clutter

    divider_length = Config::LANE_DIVIDER_LENGTH

    # Animate dividers moving toward player
    offset = distance.to_i % divider_spacing

    # Calculate divider positions (midpoint between each pair of lanes)
    divider_positions = []
    (Config::LANES.length - 1).times do |i|
      divider_x = (Config::LANES[i] + Config::LANES[i + 1]) / 2.0
      divider_positions << divider_x
    end

    # Draw dividers at multiple depths
    world_y = -offset
    while world_y < @camera.world_depth
      # Calculate scale at both ends of the divider for proper perspective
      scale_start = @camera.perspective_scale(world_y)
      scale_end = @camera.perspective_scale(world_y + divider_length)

      divider_width_start = Config::LANE_DIVIDER_WIDTH * scale_start
      divider_width_end = Config::LANE_DIVIDER_WIDTH * scale_end

      # Draw all lane dividers as trapezoids that taper toward vanishing point
      divider_positions.each do |divider_x|
        draw_divider_trapezoid(args, divider_x, world_y, divider_length,
                               divider_width_start, divider_width_end)
      end

      world_y += divider_spacing
    end
  end

  def draw_divider_trapezoid(args, divider_x, world_y, divider_length, width_start, width_end)
    # Get screen positions for near and far ends of the divider
    divider_start = @camera.world_to_screen(divider_x, world_y)
    divider_end = @camera.world_to_screen(divider_x, world_y + divider_length)

    # Calculate the four corners of the trapezoid
    bottom_left_x = divider_start.x - width_start / 2
    bottom_right_x = divider_start.x + width_start / 2
    bottom_y = divider_start.y
    
    top_left_x = divider_end.x - width_end / 2
    top_right_x = divider_end.x + width_end / 2
    top_y = divider_end.y

    # Draw the trapezoid by filling with interpolated horizontal lines
    num_fill_lines = [((top_y - bottom_y).abs / 2).to_i, 1].max
    
    num_fill_lines.times do |i|
      t = i.to_f / num_fill_lines
      
      line_y = bottom_y + (top_y - bottom_y) * t
      line_left_x = bottom_left_x + (top_left_x - bottom_left_x) * t
      line_right_x = bottom_right_x + (top_right_x - bottom_right_x) * t
      line_width = line_right_x - line_left_x
      
      args.outputs.sprites << {
        x: line_left_x,
        y: line_y,
        w: line_width,
        h: 2,
        path: :pixel,
        r: Config::LANE_DIVIDER_COLOR[:r],
        g: Config::LANE_DIVIDER_COLOR[:g],
        b: Config::LANE_DIVIDER_COLOR[:b],
        a: 200
      }
    end
  end

  def draw_road_edges(args)
    # Use cached road edge geometry (never changes)
    args.outputs.sprites << @cached_road_edges
  end

  def generate_road_edges_geometry
    # Generate the road edge geometry once at initialization
    # Get the four corners of the road trapezoid
    near_left = @camera.world_to_screen(Config::ROAD_MIN_X, 0)
    near_right = @camera.world_to_screen(Config::ROAD_MAX_X, 0)
    far_left = @camera.world_to_screen(Config::ROAD_MIN_X, @camera.world_depth)
    far_right = @camera.world_to_screen(Config::ROAD_MAX_X, @camera.world_depth)

    # Calculate total height of road on screen
    road_height = far_left[:y] - near_left[:y]

    # Generate edges as thick lines along the left and right sides
    # Use many small segments to follow the perspective curve
    edge_segments = []
    num_segments = (road_height / 2).ceil
    edge_thickness = 3

    num_segments.times do |i|
      t = i.to_f / num_segments

      # Calculate Y position
      y = near_left[:y] + (far_left[:y] - near_left[:y]) * t

      # Calculate X positions for left and right edges
      left_x = near_left[:x] + (far_left[:x] - near_left[:x]) * t
      right_x = near_right[:x] + (far_right[:x] - near_right[:x]) * t

      # Add left edge segment
      edge_segments << {
        x: left_x - edge_thickness,
        y: y,
        w: edge_thickness,
        h: 3,
        path: :pixel,
        r: Config::ROAD_EDGE_COLOR[:r],
        g: Config::ROAD_EDGE_COLOR[:g],
        b: Config::ROAD_EDGE_COLOR[:b],
        a: 255
      }

      # Add right edge segment
      edge_segments << {
        x: right_x,
        y: y,
        w: edge_thickness,
        h: 3,
        path: :pixel,
        r: Config::ROAD_EDGE_COLOR[:r],
        g: Config::ROAD_EDGE_COLOR[:g],
        b: Config::ROAD_EDGE_COLOR[:b],
        a: 255
      }
    end

    edge_segments
  end
end

