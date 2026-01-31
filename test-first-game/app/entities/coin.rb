# Coin entity class
class Coin
  attr_accessor :x, :y, :w, :h, :lane
  attr_reader :color

  def initialize(lane, distance)
    @lane = lane
    @x = Config::LANES[@lane]
    @y = distance
    @w = Config::COIN_SIZE
    @h = Config::COIN_SIZE
    @color = Config::COIN_COLOR
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

