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
    # Forgiving hitbox: 70% of visual size (slightly more generous for collectibles)
    hitbox_scale = 0.70
    hitbox_w = @w * hitbox_scale
    hitbox_h = @h * hitbox_scale

    # Center the hitbox
    hitbox_x = @x
    hitbox_y = @y

    { x: hitbox_x, y: hitbox_y, w: hitbox_w, h: hitbox_h }
  end
end

