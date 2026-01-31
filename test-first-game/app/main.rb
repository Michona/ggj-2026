# Endless Runner Game - Subway Surfers Style
# Main game loop following DragonRuby conventions

def tick args
  defaults args
  input args
  calc args
  render args
end

def defaults args
  # Screen dimensions
  args.state.screen_width ||= 1280
  args.state.screen_height ||= 720
  
  # Lane configuration
  args.state.lane_width ||= 200
  args.state.lanes ||= [340, 540, 740]  # X positions for 3 lanes
  
  # Game state
  args.state.game_over ||= false
  args.state.score ||= 0
  args.state.distance ||= 0
  
  # Player initialization
  args.state.player ||= {
    x: args.state.lanes[1],  # Start in middle lane
    y: 100,
    w: 60,
    h: 80,
    lane_index: 1,
    speed: 8.0,
    target_lane: 1,
    color: { r: 100, g: 200, b: 255 }
  }
  
  # Obstacles (buses)
  args.state.obstacles ||= []
  args.state.obstacle_spawn_timer ||= 0
  args.state.obstacle_spawn_interval ||= 60  # Frames between spawns
  
  # Collectibles (coins)
  args.state.coins ||= []
  args.state.coin_spawn_timer ||= 0
  args.state.coin_spawn_interval ||= 40
  
  # Game constants
  args.state.min_speed ||= 2.0
  args.state.speed_decay ||= 0.002
  args.state.obstacle_speed_penalty ||= 2.5
  args.state.coin_speed_boost ||= 0.5
  args.state.game_over_threshold ||= 1.5
end

def input args
  return if args.state.game_over
  
  player = args.state.player
  
  # Handle lane switching with arrow keys or A/D
  if args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_down.a
    player.target_lane = [player.target_lane - 1, 0].max
  elsif args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_down.d
    player.target_lane = [player.target_lane + 1, 2].min
  end
  
  # Handle restart
  if args.state.game_over && args.inputs.keyboard.key_down.r
    reset_game args
  end
end

def calc args
  return if args.state.game_over
  
  player = args.state.player
  
  # Update player position (smooth lane transition)
  target_x = args.state.lanes[player.target_lane]
  if player.x < target_x
    player.x = [player.x + 10, target_x].min
  elsif player.x > target_x
    player.x = [player.x - 10, target_x].max
  end
  
  if player.x == target_x
    player.lane_index = player.target_lane
  end
  
  # Decay speed over time
  player.speed -= args.state.speed_decay
  player.speed = [player.speed, args.state.min_speed].max
  
  # Update distance and score
  args.state.distance += player.speed
  args.state.score = args.state.distance.to_i
  
  # Spawn obstacles
  args.state.obstacle_spawn_timer += 1
  if args.state.obstacle_spawn_timer >= args.state.obstacle_spawn_interval
    spawn_obstacle args
    args.state.obstacle_spawn_timer = 0
  end
  
  # Spawn coins
  args.state.coin_spawn_timer += 1
  if args.state.coin_spawn_timer >= args.state.coin_spawn_interval
    spawn_coin args
    args.state.coin_spawn_timer = 0
  end
  
  # Update obstacles
  args.state.obstacles.each do |obs|
    obs.y -= player.speed * 1.5
  end
  args.state.obstacles.reject! { |obs| obs.y < -obs.h }
  
  # Update coins
  args.state.coins.each do |coin|
    coin.y -= player.speed * 1.5
  end
  args.state.coins.reject! { |coin| coin.y < -coin.h }
  
  # Check collisions with obstacles
  player_rect = { x: player.x, y: player.y, w: player.w, h: player.h }
  args.state.obstacles.each do |obs|
    if player_rect.intersect_rect?(obs)
      player.speed -= args.state.obstacle_speed_penalty
      player.speed = [player.speed, 0].max
      obs.hit = true
    end
  end
  args.state.obstacles.reject! { |obs| obs.hit }
  
  # Check collisions with coins
  args.state.coins.each do |coin|
    if player_rect.intersect_rect?(coin)
      player.speed += args.state.coin_speed_boost
      args.state.score += 10
      coin.collected = true
    end
  end
  args.state.coins.reject! { |coin| coin.collected }
  
  # Check game over condition
  if player.speed <= args.state.game_over_threshold
    args.state.game_over = true
  end
end

def render args
  # Background color
  args.outputs.background_color = [20, 20, 30]

  # Draw road lanes
  draw_road args

  # Draw obstacles
  args.state.obstacles.each do |obs|
    args.outputs.solids << {
      x: obs.x,
      y: obs.y,
      w: obs.w,
      h: obs.h,
      r: obs.color.r,
      g: obs.color.g,
      b: obs.color.b
    }
  end

  # Draw coins
  args.state.coins.each do |coin|
    args.outputs.solids << {
      x: coin.x,
      y: coin.y,
      w: coin.w,
      h: coin.h,
      r: coin.color.r,
      g: coin.color.g,
      b: coin.color.b
    }
  end

  # Draw player
  player = args.state.player
  args.outputs.solids << {
    x: player.x,
    y: player.y,
    w: player.w,
    h: player.h,
    r: player.color.r,
    g: player.color.g,
    b: player.color.b
  }

  # Draw UI
  draw_ui args

  # Draw game over screen
  if args.state.game_over
    draw_game_over args
  end
end

def draw_road args
  # Draw road background
  args.outputs.solids << {
    x: 300,
    y: 0,
    w: 680,
    h: args.state.screen_height,
    r: 60,
    g: 60,
    b: 70
  }

  # Draw lane dividers
  lane_divider_height = 40
  lane_divider_gap = 30
  offset = (args.state.distance.to_i % (lane_divider_height + lane_divider_gap))

  # Left lane divider
  y = -offset
  while y < args.state.screen_height
    args.outputs.solids << {
      x: 490,
      y: y,
      w: 10,
      h: lane_divider_height,
      r: 200,
      g: 200,
      b: 100
    }
    y += lane_divider_height + lane_divider_gap
  end

  # Right lane divider
  y = -offset
  while y < args.state.screen_height
    args.outputs.solids << {
      x: 690,
      y: y,
      w: 10,
      h: lane_divider_height,
      r: 200,
      g: 200,
      b: 100
    }
    y += lane_divider_height + lane_divider_gap
  end

  # Draw road edges
  args.outputs.solids << { x: 290, y: 0, w: 10, h: args.state.screen_height, r: 255, g: 255, b: 255 }
  args.outputs.solids << { x: 980, y: 0, w: 10, h: args.state.screen_height, r: 255, g: 255, b: 255 }
end

def draw_ui args
  player = args.state.player

  # Score
  args.outputs.labels << {
    x: 30,
    y: args.state.screen_height - 30,
    text: "Score: #{args.state.score}",
    size_px: 32,
    r: 255,
    g: 255,
    b: 255
  }

  # Speed indicator
  speed_percent = ((player.speed / 8.0) * 100).to_i
  args.outputs.labels << {
    x: 30,
    y: args.state.screen_height - 70,
    text: "Speed: #{speed_percent}%",
    size_px: 24,
    r: speed_percent > 30 ? 100 : 255,
    g: speed_percent > 30 ? 255 : 100,
    b: 100
  }

  # Speed bar
  bar_width = 200
  bar_height = 20
  bar_x = 30
  bar_y = args.state.screen_height - 110

  # Background bar
  args.outputs.solids << {
    x: bar_x,
    y: bar_y,
    w: bar_width,
    h: bar_height,
    r: 50,
    g: 50,
    b: 50
  }

  # Speed bar fill
  fill_width = (bar_width * (player.speed / 8.0)).to_i
  args.outputs.solids << {
    x: bar_x,
    y: bar_y,
    w: fill_width,
    h: bar_height,
    r: speed_percent > 30 ? 100 : 255,
    g: speed_percent > 30 ? 255 : 100,
    b: 100
  }
end

def draw_game_over args
  # Semi-transparent overlay
  args.outputs.solids << {
    x: 0,
    y: 0,
    w: args.state.screen_width,
    h: args.state.screen_height,
    r: 0,
    g: 0,
    b: 0,
    a: 180
  }

  # Game Over text
  args.outputs.labels << {
    x: args.state.screen_width / 2,
    y: args.state.screen_height / 2 + 100,
    text: "GAME OVER",
    size_px: 64,
    anchor_x: 0.5,
    anchor_y: 0.5,
    r: 255,
    g: 100,
    b: 100
  }

  # Police caught you message
  args.outputs.labels << {
    x: args.state.screen_width / 2,
    y: args.state.screen_height / 2 + 30,
    text: "The police caught you!",
    size_px: 32,
    anchor_x: 0.5,
    anchor_y: 0.5,
    r: 255,
    g: 255,
    b: 255
  }

  # Final score
  args.outputs.labels << {
    x: args.state.screen_width / 2,
    y: args.state.screen_height / 2 - 40,
    text: "Final Score: #{args.state.score}",
    size_px: 40,
    anchor_x: 0.5,
    anchor_y: 0.5,
    r: 255,
    g: 255,
    b: 100
  }

  # Restart instruction
  args.outputs.labels << {
    x: args.state.screen_width / 2,
    y: args.state.screen_height / 2 - 100,
    text: "Press R to Restart",
    size_px: 28,
    anchor_x: 0.5,
    anchor_y: 0.5,
    r: 200,
    g: 200,
    b: 200
  }
end

def spawn_obstacle args
  # Randomly choose a lane
  lane_index = rand(3)

  args.state.obstacles << {
    x: args.state.lanes[lane_index] - 10,
    y: args.state.screen_height + 50,
    w: 80,
    h: 120,
    lane_index: lane_index,
    hit: false,
    color: { r: 200, g: 50, b: 50 }
  }
end

def spawn_coin args
  # Randomly choose a lane
  lane_index = rand(3)

  args.state.coins << {
    x: args.state.lanes[lane_index] + 15,
    y: args.state.screen_height + 50,
    w: 30,
    h: 30,
    lane_index: lane_index,
    collected: false,
    color: { r: 255, g: 215, b: 0 }
  }
end

def reset_game args
  args.state.game_over = false
  args.state.score = 0
  args.state.distance = 0
  args.state.obstacles = []
  args.state.coins = []
  args.state.obstacle_spawn_timer = 0
  args.state.coin_spawn_timer = 0

  # Reset player
  args.state.player.x = args.state.lanes[1]
  args.state.player.lane_index = 1
  args.state.player.target_lane = 1
  args.state.player.speed = 8.0
end

