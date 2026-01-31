# Obstacle entity class
class Obstacle
  attr_accessor :x, :y, :w, :h
  attr_reader :color

  def initialize(x_position, width, distance)
    @x = x_position
    @w = width
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
end

