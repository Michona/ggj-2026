# Entity spawning system
class Spawner
  def initialize
    @last_obstacle_spawn = 0
    @last_coin_spawn = 0
  end

  def update(game_state)
    spawn_obstacles(game_state)
    spawn_coins(game_state)
  end

  private

  def spawn_obstacles(game_state)
    # Spawn obstacles at regular intervals
    if game_state.distance - @last_obstacle_spawn > 150
      # Random lane and lane span (1-3 lanes)
      lane_span = rand(3) + 1  # 1, 2, or 3
      max_start_lane = Config::NUM_LANES - lane_span
      lane = rand(max_start_lane + 1)  # 0 to max_start_lane

      # Always spawn at the horizon
      spawn_distance = Config::WORLD_DEPTH

      obstacle = Obstacle.new(lane, lane_span, spawn_distance)
      game_state.obstacles << obstacle

      @last_obstacle_spawn = game_state.distance
    end
  end

  def spawn_coins(game_state)
    # Spawn coins more frequently than obstacles
    if game_state.distance - @last_coin_spawn > 80
      # Random lane
      lane = rand(Config::NUM_LANES)

      # Always spawn at the horizon
      spawn_distance = Config::WORLD_DEPTH

      coin = Coin.new(lane, spawn_distance)
      game_state.coins << coin

      @last_coin_spawn = game_state.distance
    end
  end
end

