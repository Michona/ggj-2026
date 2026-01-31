# Endless Runner Game - Isometric Perspective
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

  # Isometric/Perspective settings
  args.state.vanishing_point_x ||= 640  # Center of screen
  args.state.vanishing_point_y ||= 600  # High up on screen
  args.state.perspective_strength ||= 0.7  # How much perspective scaling (0-1)
  args.state.world_depth ||= 1000  # Maximum depth in world coordinates
  args.state.camera_y_offset ||= 150  # Player appears lower on screen

  # Lane configuration (world coordinates)
  args.state.lane_width ||= 200
  args.state.lanes ||= [-800, -600, -400, -200, 0, 200, 400, 600, 800]  # X positions for 9 lanes (centered at 0)

  # Game state
  args.state.game_over ||= false
  args.state.score ||= 0
  args.state.distance ||= 0

  # Player initialization (world coordinates)
  args.state.player ||= {
    x: args.state.lanes[4],  # Start in middle lane (world x) - lane 4 is center of 9 lanes
    y: 0,  # World Y position (depth)
    w: 60,  # Base width
    h: 80,  # Base height
    lane_index: 4,
    speed: 8.0,
    target_lane: 4,
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

# ============================================================================
# ISOMETRIC PROJECTION HELPERS
# ============================================================================

# Calculate perspective scale based on depth (y position in world)
# Objects further away (higher y) appear smaller
def perspective_scale args, world_y
  # Normalize world_y to 0-1 range
  depth_ratio = world_y / args.state.world_depth
  depth_ratio = [[depth_ratio, 0].max, 1].min  # Clamp to 0-1

  # Scale from 1.0 (close) to perspective_strength (far)
  min_scale = args.state.perspective_strength
  scale = 1.0 - (depth_ratio * (1.0 - min_scale))

  return scale
end

# Convert world coordinates to isometric screen coordinates
def world_to_screen args, world_x, world_y
  scale = perspective_scale(args, world_y)

  # Calculate screen position with perspective
  # X: interpolate between world position and vanishing point based on depth
  depth_ratio = world_y / args.state.world_depth
  depth_ratio = [[depth_ratio, 0].max, 1].min

  screen_x = args.state.vanishing_point_x + (world_x * scale)

  # Y: map world depth to screen height
  # Near objects (y=0) appear at bottom, far objects (y=world_depth) appear at vanishing point
  screen_y = args.state.camera_y_offset + (depth_ratio * (args.state.vanishing_point_y - args.state.camera_y_offset))

  return { x: screen_x, y: screen_y, scale: scale }
end

# Convert world rectangle to screen rectangle with perspective
def world_rect_to_screen args, world_x, world_y, world_w, world_h
  screen_pos = world_to_screen(args, world_x, world_y)

  scaled_w = world_w * screen_pos.scale
  scaled_h = world_h * screen_pos.scale

  # Center the object on its position
  screen_x = screen_pos.x - (scaled_w / 2)
  screen_y = screen_pos.y

  return {
    x: screen_x,
    y: screen_y,
    w: scaled_w,
    h: scaled_h,
    scale: screen_pos.scale
  }
end

def input args
  return if args.state.game_over

  player = args.state.player

  # Handle lane switching with arrow keys or A/D
  if args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_down.a
    player.target_lane = [player.target_lane - 1, 0].max
  elsif args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_down.d
    player.target_lane = [player.target_lane + 1, 8].min  # 8 is max index for 9 lanes (0-8)
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
  
  # Update obstacles (move toward player in world space)
  args.state.obstacles.each do |obs|
    obs.y -= player.speed * 1.5
  end
  # Remove obstacles that passed the player
  args.state.obstacles.reject! { |obs| obs.y < -100 }

  # Update coins (move toward player in world space)
  args.state.coins.each do |coin|
    coin.y -= player.speed * 1.5
  end
  # Remove coins that passed the player
  args.state.coins.reject! { |coin| coin.y < -100 }

  # Check collisions with obstacles (in world coordinates)
  # Collision happens when objects are at similar depth and player is within obstacle's lane range
  collision_depth_threshold = 80

  args.state.obstacles.each do |obs|
    # Check if obstacle is at player's depth
    depth_diff = (obs.y - player.y).abs

    # For multi-lane obstacles, check if player's lane is within the obstacle's lane range
    player_in_obstacle_lane = false

    # Check if player's lane index falls within the obstacle's lane span
    if player.lane_index >= obs.lane_index && player.lane_index < (obs.lane_index + obs.lane_span)
      player_in_obstacle_lane = true
    end

    # Alternative check using world X coordinates for more precise collision
    # Calculate the obstacle's left and right edges in world coordinates
    obstacle_half_width = obs.w / 2.0
    obstacle_left = obs.x - obstacle_half_width
    obstacle_right = obs.x + obstacle_half_width
    player_half_width = player.w / 2.0
    player_left = player.x - player_half_width
    player_right = player.x + player_half_width

    # Check if player overlaps with obstacle horizontally
    horizontal_overlap = (player_right > obstacle_left) && (player_left < obstacle_right)

    if depth_diff < collision_depth_threshold && horizontal_overlap
      player.speed -= args.state.obstacle_speed_penalty
      player.speed = [player.speed, 0].max
      obs.hit = true
    end
  end
  args.state.obstacles.reject! { |obs| obs.hit }

  # Check collisions with coins (in world coordinates)
  args.state.coins.each do |coin|
    depth_diff = (coin.y - player.y).abs

    # Check horizontal overlap with coin
    coin_half_width = coin.w / 2.0
    coin_left = coin.x - coin_half_width
    coin_right = coin.x + coin_half_width
    player_half_width = player.w / 2.0
    player_left = player.x - player_half_width
    player_right = player.x + player_half_width

    horizontal_overlap = (player_right > coin_left) && (player_left < coin_right)

    if depth_diff < collision_depth_threshold && horizontal_overlap
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
  # Background color (darker for depth)
  args.outputs.background_color = [15, 20, 25]

  # RENDER ORDER:
  # 1. Road surface (background)
  # 2. Lane dividers (on road)
  # 3. Game objects (player, obstacles, coins) in depth order
  # 4. Road edges (lines on top for visual clarity)
  # 5. UI (always on top)

  # Draw road surface first (background)
  draw_road_surface args

  # Draw lane dividers
  draw_lane_dividers args

  # Collect all game objects with their depth for sorting
  render_objects = []

  # Add obstacles
  args.state.obstacles.each do |obs|
    screen_rect = world_rect_to_screen(args, obs.x, obs.y, obs.w, obs.h)
    render_objects << {
      depth: obs.y,
      primitive: {
        x: screen_rect.x,
        y: screen_rect.y,
        w: screen_rect.w,
        h: screen_rect.h,
        r: obs.color.r,
        g: obs.color.g,
        b: obs.color.b
      }
    }
  end

  # Add coins
  args.state.coins.each do |coin|
    screen_rect = world_rect_to_screen(args, coin.x, coin.y, coin.w, coin.h)
    render_objects << {
      depth: coin.y,
      primitive: {
        x: screen_rect.x,
        y: screen_rect.y,
        w: screen_rect.w,
        h: screen_rect.h,
        r: coin.color.r,
        g: coin.color.g,
        b: coin.color.b
      }
    }
  end

  # Add player
  player = args.state.player
  screen_rect = world_rect_to_screen(args, player.x, player.y, player.w, player.h)
  render_objects << {
    depth: player.y,
    primitive: {
      x: screen_rect.x,
      y: screen_rect.y,
      w: screen_rect.w,
      h: screen_rect.h,
      r: player.color.r,
      g: player.color.g,
      b: player.color.b
    }
  }

  # Sort by depth (render far objects first)
  render_objects = render_objects.sort_by { |obj| -obj.depth }

  # Render all objects in depth order
  render_objects.each do |obj|
    args.outputs.solids << obj.primitive
  end

  # Draw road edges on top for visual clarity
  draw_road_edges args

  # Draw UI (always on top)
  draw_ui args

  # Draw game over screen
  if args.state.game_over
    draw_game_over args
  end
end

def draw_road_surface args
  # Draw road as a large rectangle approximating the trapezoid
  # This renders in the background using solids

  # Near position (bottom of screen) - expanded for 9 lanes
  near_depth = 0
  near_left = world_to_screen(args, -1000, near_depth)  # Extended left edge
  near_right = world_to_screen(args, 1000, near_depth)  # Extended right edge

  # Far position (vanishing point)
  far_depth = args.state.world_depth
  far_left = world_to_screen(args, -1000, far_depth)
  far_right = world_to_screen(args, 1000, far_depth)

  # Draw road as a simple rectangle covering the play area
  # This ensures it's behind everything else
  road_x = [near_left.x, far_left.x].min
  road_y = near_left.y
  road_w = [near_right.x, far_right.x].max - road_x
  road_h = far_left.y - near_left.y

  args.outputs.solids << {
    x: road_x,
    y: road_y,
    w: road_w,
    h: road_h,
    r: 50,
    g: 55,
    b: 60
  }
end

def draw_road_edges args
  # Draw road edges as lines (rendered after game objects for visual clarity)
  # Near position (bottom of screen) - expanded for 9 lanes
  near_depth = 0
  near_left = world_to_screen(args, -1000, near_depth)
  near_right = world_to_screen(args, 1000, near_depth)

  # Far position (vanishing point)
  far_depth = args.state.world_depth
  far_left = world_to_screen(args, -1000, far_depth)
  far_right = world_to_screen(args, 1000, far_depth)

  # Left edge
  args.outputs.lines << {
    x: near_left.x,
    y: near_left.y,
    x2: far_left.x,
    y2: far_left.y,
    r: 200,
    g: 200,
    b: 200,
    a: 255
  }

  # Right edge
  args.outputs.lines << {
    x: near_right.x,
    y: near_right.y,
    x2: far_right.x,
    y2: far_right.y,
    r: 200,
    g: 200,
    b: 200,
    a: 255
  }
end

def draw_lane_dividers args
  # Draw lane dividers between the 9 lanes (8 dividers total)
  # Dividers are positioned between each pair of adjacent lanes

  divider_spacing = 60  # World space between divider segments
  divider_length = 40   # World space length of each segment

  # Animate dividers moving toward player
  offset = args.state.distance.to_i % divider_spacing

  # Calculate divider positions (midpoint between each pair of lanes)
  # For 9 lanes at [-800, -600, -400, -200, 0, 200, 400, 600, 800]
  # Dividers are at [-700, -500, -300, -100, 100, 300, 500, 700]
  divider_positions = []
  (args.state.lanes.length - 1).times do |i|
    divider_x = (args.state.lanes[i] + args.state.lanes[i + 1]) / 2.0
    divider_positions << divider_x
  end

  # Draw dividers at multiple depths
  world_y = offset
  while world_y < args.state.world_depth
    scale = perspective_scale(args, world_y)
    divider_width = 8 * scale

    # Draw all 8 lane dividers
    divider_positions.each do |divider_x|
      divider_start = world_to_screen(args, divider_x, world_y)
      divider_end = world_to_screen(args, divider_x, world_y + divider_length)

      args.outputs.solids << {
        x: divider_start.x - divider_width / 2,
        y: divider_start.y,
        w: divider_width,
        h: divider_end.y - divider_start.y,
        r: 200,
        g: 200,
        b: 100,
        a: 200
      }
    end

    world_y += divider_spacing
  end
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
  # Randomly choose a starting lane (0-8 for 9 lanes)
  lane_index = rand(9)

  # Randomly choose how many lanes this obstacle spans (1, 2, or 3 lanes)
  lane_span = [1, 1, 1, 2, 2, 3].sample  # Weighted: more single-lane, fewer triple-lane

  # Ensure obstacle doesn't go beyond the rightmost lane
  if lane_index + lane_span > 9
    lane_index = 9 - lane_span
  end

  # Calculate obstacle position (centered on the spanned lanes)
  # For multi-lane obstacles, position at the center of the spanned lanes
  start_lane_x = args.state.lanes[lane_index]
  end_lane_x = args.state.lanes[lane_index + lane_span - 1]
  obstacle_x = (start_lane_x + end_lane_x) / 2.0

  # Calculate obstacle width based on lane span
  # Width should cover all spanned lanes plus some overlap
  base_width = 80
  obstacle_width = (lane_span * args.state.lane_width) - 40  # Slight gap on edges

  # Spawn at far depth (world coordinates)
  args.state.obstacles << {
    x: obstacle_x,  # World X position (center of spanned lanes)
    y: args.state.world_depth,  # Spawn at far depth
    w: obstacle_width,
    h: 120,
    lane_index: lane_index,  # Starting lane
    lane_span: lane_span,  # How many lanes it spans
    hit: false,
    color: { r: 200, g: 50, b: 50 }
  }
end

def spawn_coin args
  # Randomly choose a lane (0-8 for 9 lanes)
  lane_index = rand(9)

  # Spawn at far depth (world coordinates)
  args.state.coins << {
    x: args.state.lanes[lane_index],  # World X position
    y: args.state.world_depth,  # Spawn at far depth
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

  # Reset player (world coordinates)
  args.state.player.x = args.state.lanes[4]  # Middle lane (lane 4 is center of 9 lanes)
  args.state.player.y = 0  # At player's depth
  args.state.player.lane_index = 4
  args.state.player.target_lane = 4
  args.state.player.speed = 8.0
end

