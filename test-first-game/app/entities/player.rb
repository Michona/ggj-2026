# Player entity class
class Player
  attr_accessor :x, :y, :w, :h, :speed, :target_lane, :current_lane
  attr_reader :color, :lean_angle

  def initialize
    @current_lane = Config::PLAYER_START_LANE
    @target_lane = Config::PLAYER_START_LANE
    @x = Config::LANES[@current_lane]
    @y = Config::PLAYER_Y_POSITION
    @w = Config::PLAYER_WIDTH
    @h = Config::PLAYER_HEIGHT
    @speed = Config::PLAYER_START_SPEED
    @color = Config::PLAYER_COLOR
    @lean_angle = 0  # Rotation angle for lean animation
  end

  def update
    # Smoothly move toward target lane
    target_x = Config::LANES[@target_lane]
    previous_x = @x

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

    # Update lean angle based on movement direction
    update_lean_angle(previous_x)
  end

  def update_lean_angle(previous_x)
    # Calculate lean based on horizontal movement
    max_lean = 5  # Maximum lean angle in degrees

    if @x > previous_x
      # Moving right - lean right
      @lean_angle = -max_lean
    elsif @x < previous_x
      # Moving left - lean left
      @lean_angle = max_lean
    else
      # Not moving - return to upright
      # Smoothly interpolate back to 0
      @lean_angle *= 0.8
      @lean_angle = 0 if @lean_angle.abs < 0.1
    end
  end

  def move_left
    @target_lane = [@target_lane - 1, 0].max
  end

  def move_right
    @target_lane = [@target_lane + 1, Config::NUM_LANES - 1].min
  end

  def hit_obstacle(camera = nil)
    @speed -= Config::SPEED_DECAY_ON_HIT
    @speed = [@speed, 0].max

    # Trigger camera shake on impact
    camera.trigger_shake(5) if camera
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
    # Forgiving hitbox: 65% of visual size, centered at bottom (feet)
    # This prevents frustrating collisions in isometric view
    hitbox_scale = 0.65
    hitbox_w = @w * hitbox_scale
    hitbox_h = @h * hitbox_scale

    # Center horizontally, align to bottom vertically
    hitbox_x = @x
    hitbox_y = @y

    { x: hitbox_x, y: hitbox_y, w: hitbox_w, h: hitbox_h }
  end
end

