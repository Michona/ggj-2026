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
      # Random width between min and max
      width = Config::OBSTACLE_MIN_WIDTH + rand(Config::OBSTACLE_MAX_WIDTH - Config::OBSTACLE_MIN_WIDTH)

      # Random X position within road bounds (accounting for obstacle width)
      # Ensure the obstacle stays fully within the road
      half_width = width / 2.0
      min_x = Config::ROAD_MIN_X + half_width
      max_x = Config::ROAD_MAX_X - half_width
      x_position = min_x + rand((max_x - min_x).to_i)

      # Always spawn at the horizon
      spawn_distance = Config::WORLD_DEPTH

      obstacle = Obstacle.new(x_position, width, spawn_distance)
      game_state.obstacles << obstacle

      @last_obstacle_spawn = game_state.distance
    end
  end

  def spawn_coins(game_state)
    # Spawn coins more frequently than obstacles
    if game_state.distance - @last_coin_spawn > 80
      # Random X position within road bounds (accounting for coin size)
      half_size = Config::COIN_SIZE / 2.0
      min_x = Config::ROAD_MIN_X + half_size
      max_x = Config::ROAD_MAX_X - half_size
      x_position = min_x + rand((max_x - min_x).to_i)

      # Always spawn at the horizon
      spawn_distance = Config::WORLD_DEPTH

      coin = Coin.new(x_position, spawn_distance)
      game_state.coins << coin

      @last_coin_spawn = game_state.distance
    end
  end
end

