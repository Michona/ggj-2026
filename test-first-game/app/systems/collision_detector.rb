# Collision detection system
class CollisionDetector
  def check_collisions(game_state, camera = nil)
    player = game_state.player
    player_bounds = player.bounds

    # Check obstacle collisions
    game_state.obstacles.each do |obstacle|
      if boxes_overlap?(player_bounds, obstacle.bounds)
        player.hit_obstacle(camera)
        game_state.obstacles.delete(obstacle)
      end
    end

    # Check coin collisions
    game_state.coins.each do |coin|
      if boxes_overlap?(player_bounds, coin.bounds)
        player.collect_coin
        game_state.score += Config::COIN_SCORE_VALUE
        game_state.coins.delete(coin)
      end
    end
  end

  private

  # Check if two bounding boxes overlap
  def boxes_overlap?(box1, box2)
    # Calculate half-widths and half-heights
    half_w1 = box1[:w] / 2.0
    half_h1 = box1[:h] / 2.0
    half_w2 = box2[:w] / 2.0
    half_h2 = box2[:h] / 2.0

    # Calculate centers
    center1_x = box1[:x]
    center1_y = box1[:y] + half_h1
    center2_x = box2[:x]
    center2_y = box2[:y] + half_h2

    # Check for overlap
    x_overlap = (center1_x - center2_x).abs < (half_w1 + half_w2)
    y_overlap = (center1_y - center2_y).abs < (half_h1 + half_h2)

    return x_overlap && y_overlap
  end
end

