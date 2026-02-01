# Entity spawning system with smart lane-based logic
class Spawner
  # Depth segment size for ensuring at least one lane is always open
  SEGMENT_DEPTH = 300

  def initialize
    @last_obstacle_spawn = 0
    @last_coin_spawn = 0
    # Track which lanes are blocked in the current depth segment
    @blocked_lanes_in_segment = []
    @current_segment_start = 0
  end

  def update(game_state)
    spawn_obstacles(game_state)
    spawn_coins(game_state)
  end

  private

  def spawn_obstacles(game_state)
    # Calculate spawn interval based on difficulty
    # As difficulty increases, obstacles spawn more frequently
    spawn_interval = calculate_obstacle_spawn_interval(game_state.difficulty_multiplier)

    # Spawn obstacles at intervals that decrease with difficulty
    if game_state.distance - @last_obstacle_spawn > spawn_interval
      # Check if we've moved to a new depth segment
      current_segment = (game_state.distance / SEGMENT_DEPTH).to_i
      if current_segment != @current_segment_start
        # Reset blocked lanes for new segment
        @blocked_lanes_in_segment = []
        @current_segment_start = current_segment
      end

      # Determine obstacle lane and span
      lane, lane_span = choose_safe_obstacle_placement(game_state)

      # Always spawn at the horizon
      spawn_distance = Config::WORLD_DEPTH

      obstacle = Obstacle.new(lane, lane_span, spawn_distance)
      game_state.obstacles << obstacle

      # Track which lanes this obstacle blocks
      (lane...(lane + lane_span)).each do |blocked_lane|
        @blocked_lanes_in_segment << blocked_lane unless @blocked_lanes_in_segment.include?(blocked_lane)
      end

      @last_obstacle_spawn = game_state.distance
    end
  end

  def calculate_obstacle_spawn_interval(difficulty_multiplier)
    # Interpolate between base and minimum spawn interval based on difficulty
    base = Config::BASE_OBSTACLE_SPAWN_INTERVAL
    min = Config::MIN_OBSTACLE_SPAWN_INTERVAL

    # As difficulty goes from 1.0 to MAX, interval goes from base to min
    normalized_difficulty = (difficulty_multiplier - 1.0) / (Config::MAX_DIFFICULTY_MULTIPLIER - 1.0)
    normalized_difficulty = [[normalized_difficulty, 0].max, 1].min

    interval = base - (base - min) * normalized_difficulty
    interval.to_i
  end

  def choose_safe_obstacle_placement(game_state)
    # Determine how many lanes this obstacle will span (1-2 lanes)
    lane_span = rand(2) + 1  # 1 or 2 lanes

    # Find all valid starting lanes for this span
    valid_lanes = []
    (0...(Config::NUM_LANES - lane_span + 1)).each do |start_lane|
      # Check if placing obstacle here would block all lanes
      would_block = (start_lane...(start_lane + lane_span)).to_a
      potential_blocked = (@blocked_lanes_in_segment + would_block).uniq

      # Only allow this placement if at least one lane remains open
      if potential_blocked.length < Config::NUM_LANES
        valid_lanes << start_lane
      end
    end

    # If no valid lanes (shouldn't happen, but safety check), allow any lane
    valid_lanes = (0...(Config::NUM_LANES - lane_span + 1)).to_a if valid_lanes.empty?

    # Choose a random valid lane
    lane = valid_lanes.sample

    return [lane, lane_span]
  end

  def spawn_coins(game_state)
    # Spawn coins more frequently than obstacles
    if game_state.distance - @last_coin_spawn > 80
      # Random lane for coin
      lane = rand(Config::NUM_LANES)

      # Always spawn at the horizon
      spawn_distance = Config::WORLD_DEPTH

      coin = Coin.new(lane, spawn_distance)
      game_state.coins << coin

      @last_coin_spawn = game_state.distance
    end
  end
end

