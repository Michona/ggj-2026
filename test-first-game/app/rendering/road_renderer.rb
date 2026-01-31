# Road rendering system
class RoadRenderer
  def initialize(camera)
    @camera = camera
  end

  def render(args, distance)
    draw_road_surface(args)
    draw_lane_dividers(args, distance)
    draw_road_edges(args)
  end

  private

  def draw_road_surface(args)
    # Draw the main road surface as a trapezoid
    # Near edge (bottom of screen, close to player)
    near_left = @camera.world_to_screen(Config::LANES.first - Config::LANE_WIDTH / 2, 0)
    near_right = @camera.world_to_screen(Config::LANES.last + Config::LANE_WIDTH / 2, 0)

    # Far edge (vanishing point)
    far_left = @camera.world_to_screen(Config::LANES.first - Config::LANE_WIDTH / 2, @camera.world_depth)
    far_right = @camera.world_to_screen(Config::LANES.last + Config::LANE_WIDTH / 2, @camera.world_depth)

    # Draw road as a solid trapezoid (approximated with a large rectangle)
    # For simplicity, we'll draw it as a filled polygon using multiple horizontal lines
    num_lines = 100
    num_lines.times do |i|
      t = i.to_f / num_lines
      
      y = near_left.y + (far_left.y - near_left.y) * t
      left_x = near_left.x + (far_left.x - near_left.x) * t
      right_x = near_right.x + (far_right.x - near_right.x) * t
      
      args.outputs.solids << {
        x: left_x,
        y: y,
        w: right_x - left_x,
        h: 5,
        r: Config::ROAD_COLOR[:r],
        g: Config::ROAD_COLOR[:g],
        b: Config::ROAD_COLOR[:b]
      }
    end
  end

  def draw_lane_dividers(args, distance)
    # Draw lane dividers between the 9 lanes (8 dividers total)
    divider_spacing = Config::LANE_DIVIDER_SPACING
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

      # Draw all 8 lane dividers as trapezoids that taper toward vanishing point
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
      
      args.outputs.solids << {
        x: line_left_x,
        y: line_y,
        w: line_width,
        h: 2,
        r: Config::LANE_DIVIDER_COLOR[:r],
        g: Config::LANE_DIVIDER_COLOR[:g],
        b: Config::LANE_DIVIDER_COLOR[:b],
        a: 200
      }
    end
  end

  def draw_road_edges(args)
    # Draw left edge
    near_left = @camera.world_to_screen(Config::LANES.first - Config::LANE_WIDTH / 2, 0)
    far_left = @camera.world_to_screen(Config::LANES.first - Config::LANE_WIDTH / 2, @camera.world_depth)

    args.outputs.lines << {
      x: near_left.x,
      y: near_left.y,
      x2: far_left.x,
      y2: far_left.y,
      r: Config::ROAD_EDGE_COLOR[:r],
      g: Config::ROAD_EDGE_COLOR[:g],
      b: Config::ROAD_EDGE_COLOR[:b],
      a: 255
    }

    # Draw right edge
    near_right = @camera.world_to_screen(Config::LANES.last + Config::LANE_WIDTH / 2, 0)
    far_right = @camera.world_to_screen(Config::LANES.last + Config::LANE_WIDTH / 2, @camera.world_depth)

    args.outputs.lines << {
      x: near_right.x,
      y: near_right.y,
      x2: far_right.x,
      y2: far_right.y,
      r: Config::ROAD_EDGE_COLOR[:r],
      g: Config::ROAD_EDGE_COLOR[:g],
      b: Config::ROAD_EDGE_COLOR[:b],
      a: 255
    }
  end
end

