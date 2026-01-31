# Player entity class
class Player
  attr_accessor :x, :y, :w, :h, :speed, :target_lane, :current_lane
  attr_reader :color

  def initialize
    @current_lane = Config::PLAYER_START_LANE
    @target_lane = Config::PLAYER_START_LANE
    @x = Config::LANES[@current_lane]
    @y = Config::PLAYER_Y_POSITION
    @w = Config::PLAYER_WIDTH
    @h = Config::PLAYER_HEIGHT
    @speed = Config::PLAYER_START_SPEED
    @color = Config::PLAYER_COLOR
  end

  def update
    # Smoothly move toward target lane
    target_x = Config::LANES[@target_lane]
    if @x < target_x
      @x += Config::PLAYER_LANE_SWITCH_SPEED
      @x = target_x if @x > target_x
    elsif @x > target_x
      @x -= Config::PLAYER_LANE_SWITCH_SPEED
      @x = target_x if @x < target_x
    end

    # Update current lane when we reach target
    if @x == target_x
      @current_lane = @target_lane
    end
  end

  def move_left
    @target_lane = [@target_lane - 1, 0].max
  end

  def move_right
    @target_lane = [@target_lane + 1, Config::NUM_LANES - 1].min
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
    @current_lane = Config::PLAYER_START_LANE
    @target_lane = Config::PLAYER_START_LANE
    @x = Config::LANES[@current_lane]
    @y = Config::PLAYER_Y_POSITION
    @speed = Config::PLAYER_START_SPEED
  end

  def bounds
    { x: @x, y: @y, w: @w, h: @h }
  end
end

