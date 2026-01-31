# Player entity class
class Player
  attr_accessor :x, :y, :w, :h, :speed, :horizontal_velocity
  attr_reader :color

  def initialize
    @x = Config::PLAYER_START_X
    @y = Config::PLAYER_Y_POSITION
    @w = Config::PLAYER_WIDTH
    @h = Config::PLAYER_HEIGHT
    @speed = Config::PLAYER_START_SPEED
    @horizontal_velocity = 0  # Current horizontal movement speed
    @color = Config::PLAYER_COLOR
  end

  def update
    # Apply horizontal velocity
    @x += @horizontal_velocity

    # Clamp to road boundaries
    @x = [[@x, Config::ROAD_MIN_X].max, Config::ROAD_MAX_X].min
  end

  def move_left
    @horizontal_velocity = -Config::PLAYER_HORIZONTAL_SPEED
  end

  def move_right
    @horizontal_velocity = Config::PLAYER_HORIZONTAL_SPEED
  end

  def stop_horizontal_movement
    @horizontal_velocity = 0
  end

  def hit_obstacle
    @speed -= Config::SPEED_DECAY_ON_HIT
    @speed = [@speed, 0].max
  end

  def collect_coin
    @speed += Config::COIN_SPEED_BOOST
  end

  def game_over?
    @speed <= Config::GAME_OVER_THRESHOLD
  end

  def reset
    @x = Config::PLAYER_START_X
    @y = Config::PLAYER_Y_POSITION
    @speed = Config::PLAYER_START_SPEED
    @horizontal_velocity = 0
  end

  def bounds
    { x: @x, y: @y, w: @w, h: @h }
  end
end

