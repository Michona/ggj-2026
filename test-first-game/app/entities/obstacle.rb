# Obstacle entity class
class Obstacle
  attr_accessor :x, :y, :w, :h, :lane, :lane_span
  attr_reader :color

  def initialize(lane, lane_span, distance)
    @lane = lane
    @lane_span = lane_span
    
    # Calculate position and size based on lane span
    lane_start_x = Config::LANES[@lane]
    lane_end_x = Config::LANES[@lane + @lane_span - 1]
    @x = (lane_start_x + lane_end_x) / 2.0
    @w = (lane_end_x - lane_start_x).abs + Config::LANE_WIDTH
    
    @y = distance
    @h = Config::OBSTACLE_HEIGHT
    @color = Config::OBSTACLE_COLORS.sample
  end

  def update(player_speed)
    # Move toward player at constant world-space speed
    # The perspective projection will handle making objects appear to accelerate on screen
    @y -= player_speed
  end

  def off_screen?
    @y < -100  # Off screen behind player
  end

  def bounds
    { x: @x, y: @y, w: @w, h: @h }
  end

  # Check if obstacle occupies a specific lane
  def occupies_lane?(lane_index)
    lane_index >= @lane && lane_index < (@lane + @lane_span)
  end
end

