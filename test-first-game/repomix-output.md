This file is a merged representation of the entire codebase, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
```
app/
  config/
    constants.rb
  entities/
    coin.rb
    obstacle.rb
    player.rb
  rendering/
    perspective_camera.rb
    renderer.rb
    road_renderer.rb
    ui_renderer.rb
  systems/
    collision_detector.rb
    input_handler.rb
    spawner.rb
  game_state.rb
  game.rb
  main.rb
README.md
```

# Files

## File: app/config/constants.rb
```ruby
# Game configuration and constants
module Config
  # Screen dimensions
  SCREEN_WIDTH = 1280
  SCREEN_HEIGHT = 720

  # Perspective settings - OutRun style
  VANISHING_POINT_X = 640  # Center of screen (horizontal)
  VANISHING_POINT_Y = 680  # Horizon near top of screen (~94% screen height)
  PERSPECTIVE_STRENGTH = 0.15  # Very aggressive scaling - distant objects much smaller (prevents stretching)
  WORLD_DEPTH = 1000  # Maximum depth in world coordinates
  CAMERA_Y_OFFSET = 0  # Road starts at bottom of screen (y=0)

  # Road configuration (world coordinates)
  ROAD_MIN_X = -450  # Left edge of road
  ROAD_MAX_X = 450   # Right edge of road
  ROAD_WIDTH = ROAD_MAX_X - ROAD_MIN_X  # Total road width

  # Lane markings (for visual reference only, not used for gameplay)
  LANE_DIVIDER_POSITIONS = [-150, 150]  # X positions of the 2 lane dividers

  # Player settings
  PLAYER_START_X = 0  # Center of road (world coordinates)
  PLAYER_START_SPEED = 8.0
  PLAYER_WIDTH = 40
  PLAYER_HEIGHT = 60
  PLAYER_Y_POSITION = 0  # Player is always at the front
  PLAYER_HORIZONTAL_SPEED = 10  # How fast player moves left/right
  PLAYER_COLOR = { r: 50, g: 150, b: 255 }  # Blue

  # Obstacle settings
  OBSTACLE_MIN_WIDTH = 60   # Minimum obstacle width
  OBSTACLE_MAX_WIDTH = 200  # Maximum obstacle width
  OBSTACLE_HEIGHT = 100
  OBSTACLE_BASE_SPEED = 8.0
  OBSTACLE_COLORS = [
    { r: 200, g: 50, b: 50 },   # Red
    { r: 150, g: 50, b: 150 },  # Purple
    { r: 50, g: 150, b: 100 }   # Teal
  ]

  # Coin settings
  COIN_SIZE = 30
  COIN_BASE_SPEED = 8.0
  COIN_SPEED_BOOST = 0.5
  COIN_SCORE_VALUE = 10
  COIN_COLOR = { r: 255, g: 215, b: 0 }  # Gold

  # Game mechanics
  GAME_OVER_THRESHOLD = 0.1
  SPEED_DECAY_ON_HIT = 2.0
  DISTANCE_MULTIPLIER = 0.1  # How fast distance accumulates

  # Road rendering
  ROAD_COLOR = { r: 40, g: 45, b: 50 }
  ROAD_EDGE_COLOR = { r: 200, g: 200, b: 200 }
  LANE_DIVIDER_COLOR = { r: 200, g: 200, b: 100 }
  LANE_DIVIDER_WIDTH = 8
  LANE_DIVIDER_SPACING = 60  # World space between divider segments
  LANE_DIVIDER_LENGTH = 40   # World space length of each segment

  # UI settings
  UI_TEXT_COLOR = { r: 255, g: 255, b: 255 }
  UI_FONT_SIZE = 4
  GAME_OVER_FONT_SIZE = 10
end
```

## File: app/entities/coin.rb
```ruby
# Coin entity class
class Coin
  attr_accessor :x, :y, :w, :h
  attr_reader :color

  def initialize(x_position, distance)
    @x = x_position
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
    { x: @x, y: @y, w: @w, h: @h }
  end
end
```

## File: app/entities/obstacle.rb
```ruby
# Obstacle entity class
class Obstacle
  attr_accessor :x, :y, :w, :h
  attr_reader :color

  def initialize(x_position, width, distance)
    @x = x_position
    @w = width
    @y = distance
    @h = Config::OBSTACLE_HEIGHT
    @color = Config::OBSTACLE_COLORS.sample
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
    { x: @x, y: @y, w: @w, h: @h }
  end
end
```

## File: app/entities/player.rb
```ruby
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
```

## File: app/rendering/perspective_camera.rb
```ruby
# Perspective camera for isometric/pseudo-3D rendering
class PerspectiveCamera
  def initialize
    @vanishing_point_x = Config::VANISHING_POINT_X
    @vanishing_point_y = Config::VANISHING_POINT_Y
    @perspective_strength = Config::PERSPECTIVE_STRENGTH
    @world_depth = Config::WORLD_DEPTH
    @camera_y_offset = Config::CAMERA_Y_OFFSET
  end

  # Calculate perspective scale based on depth (y position in world)
  # Objects further away (higher y) appear smaller
  def perspective_scale(world_y)
    # Normalize world_y to 0-1 range
    depth_ratio = world_y / @world_depth
    depth_ratio = [[depth_ratio, 0].max, 1].min  # Clamp to 0-1

    # Scale from 1.0 (close) to perspective_strength (far)
    min_scale = @perspective_strength
    scale = 1.0 - (depth_ratio * (1.0 - min_scale))

    return scale
  end

  # Convert world coordinates to isometric screen coordinates
  def world_to_screen(world_x, world_y)
    scale = perspective_scale(world_y)

    # Calculate screen position with perspective
    # X: interpolate between world position and vanishing point based on depth
    depth_ratio = world_y / @world_depth
    depth_ratio = [[depth_ratio, 0].max, 1].min

    screen_x = @vanishing_point_x + (world_x * scale)

    # Y: map world depth to screen height
    # Near objects (y=0) appear at bottom, far objects (y=world_depth) appear at vanishing point
    screen_y = @camera_y_offset + (depth_ratio * (@vanishing_point_y - @camera_y_offset))

    return { x: screen_x, y: screen_y, scale: scale }
  end

  # Convert world rectangle to screen rectangle with perspective
  # Scales both width and height uniformly to maintain aspect ratio
  def world_rect_to_screen(world_x, world_y, world_w, world_h)
    # Get screen position and scale at the object's depth
    screen_pos = world_to_screen(world_x, world_y)

    # Scale both width and height uniformly by perspective
    scaled_w = world_w * screen_pos[:scale]
    scaled_h = world_h * screen_pos[:scale]

    # Center the object horizontally on its position
    screen_x = screen_pos[:x] - (scaled_w / 2)

    # Y position - center vertically or use base position
    screen_y = screen_pos[:y]

    return {
      x: screen_x,
      y: screen_y,
      w: scaled_w,
      h: scaled_h,
      scale: screen_pos[:scale]
    }
  end

  attr_reader :vanishing_point_x, :vanishing_point_y, :world_depth, :camera_y_offset
end
```

## File: app/rendering/renderer.rb
```ruby
# Main rendering orchestrator
class Renderer
  def initialize
    @camera = PerspectiveCamera.new
    @road_renderer = RoadRenderer.new(@camera)
    @ui_renderer = UIRenderer.new
  end

  def render(args, game_state)
    # Background color (darker for depth)
    args.outputs.background_color = [15, 20, 25]

    # RENDER ORDER:
    # 1. Road surface (background)
    # 2. Road edges (lines under everything)
    # 3. Lane dividers (on road)
    # 4. Game objects (player, obstacles, coins) in depth order - should be ON TOP of road edges
    # 5. UI (always on top)

    # Draw road (use road_offset which moves at same speed as objects)
    # Road edges are drawn first so objects appear on top of them
    @road_renderer.render(args, game_state.road_offset)

    # Draw game objects in depth order
    render_game_objects(args, game_state)

    # Draw UI
    if game_state.game_over
      @ui_renderer.render_game_over(args, game_state.score, game_state.distance)
    else
      @ui_renderer.render_hud(args, game_state.score, game_state.distance, game_state.player.speed)
    end
  end

  private

  def render_game_objects(args, game_state)
    # Collect all game objects with their depth for sorting
    render_objects = []

    # Add obstacles
    game_state.obstacles.each do |obs|
      screen_rect = @camera.world_rect_to_screen(obs.x, obs.y, obs.w, obs.h)
      render_objects << {
        depth: obs.y,
        primitive: {
          x: screen_rect[:x],
          y: screen_rect[:y],
          w: screen_rect[:w],
          h: screen_rect[:h],
          r: obs.color[:r],
          g: obs.color[:g],
          b: obs.color[:b]
        }
      }
    end

    # Add coins
    game_state.coins.each do |coin|
      screen_rect = @camera.world_rect_to_screen(coin.x, coin.y, coin.w, coin.h)
      render_objects << {
        depth: coin.y,
        primitive: {
          x: screen_rect[:x],
          y: screen_rect[:y],
          w: screen_rect[:w],
          h: screen_rect[:h],
          r: coin.color[:r],
          g: coin.color[:g],
          b: coin.color[:b]
        }
      }
    end

    # Add player
    player = game_state.player
    screen_rect = @camera.world_rect_to_screen(player.x, player.y, player.w, player.h)
    render_objects << {
      depth: player.y,
      primitive: {
        x: screen_rect[:x],
        y: screen_rect[:y],
        w: screen_rect[:w],
        h: screen_rect[:h],
        r: player.color[:r],
        g: player.color[:g],
        b: player.color[:b]
      }
    }

    # Sort by depth (render far objects first)
    render_objects = render_objects.sort_by { |obj| -obj[:depth] }

    # Render all objects in depth order
    render_objects.each do |obj|
      args.outputs.solids << obj[:primitive]
    end
  end

  attr_reader :camera
end
```

## File: app/rendering/road_renderer.rb
```ruby
# Road rendering system
class RoadRenderer
  def initialize(camera)
    @camera = camera
  end

  def render(args, distance)
    draw_road_surface(args)
    draw_lane_dividers(args, distance)
    draw_road_edges(args)
  end

  private

  def draw_road_surface(args)
    # Draw the main road surface as a trapezoid
    # Near edge (bottom of screen, close to player)
    near_left = @camera.world_to_screen(Config::ROAD_MIN_X, 0)
    near_right = @camera.world_to_screen(Config::ROAD_MAX_X, 0)

    # Far edge (vanishing point)
    far_left = @camera.world_to_screen(Config::ROAD_MIN_X, @camera.world_depth)
    far_right = @camera.world_to_screen(Config::ROAD_MAX_X, @camera.world_depth)

    # Calculate total height of road on screen
    road_height = far_left[:y] - near_left[:y]

    # Draw road as a solid trapezoid using horizontal lines
    # Use enough lines to fill completely without gaps
    num_lines = (road_height / 2).ceil  # One line every 2 pixels
    num_lines.times do |i|
      t = i.to_f / num_lines

      y = near_left[:y] + (far_left[:y] - near_left[:y]) * t
      left_x = near_left[:x] + (far_left[:x] - near_left[:x]) * t
      right_x = near_right[:x] + (far_right[:x] - near_right[:x]) * t

      args.outputs.solids << {
        x: left_x,
        y: y,
        w: right_x - left_x,
        h: 3,  # Slightly overlapping to ensure no gaps
        r: Config::ROAD_COLOR[:r],
        g: Config::ROAD_COLOR[:g],
        b: Config::ROAD_COLOR[:b]
      }
    end
  end

  def draw_lane_dividers(args, distance)
    # Draw only 2 lane dividers (creating 3 visible lanes in the center)
    # These are purely visual - gameplay uses continuous coordinates
    divider_spacing = Config::LANE_DIVIDER_SPACING
    divider_length = Config::LANE_DIVIDER_LENGTH

    # Animate dividers moving toward player
    offset = distance.to_i % divider_spacing

    # Use the predefined divider positions from config
    divider_positions = Config::LANE_DIVIDER_POSITIONS

    # Draw dividers at multiple depths
    world_y = -offset
    while world_y < @camera.world_depth
      # Calculate scale at both ends of the divider for proper perspective
      scale_start = @camera.perspective_scale(world_y)
      scale_end = @camera.perspective_scale(world_y + divider_length)

      divider_width_start = Config::LANE_DIVIDER_WIDTH * scale_start
      divider_width_end = Config::LANE_DIVIDER_WIDTH * scale_end

      # Draw the 2 lane dividers as trapezoids that taper toward vanishing point
      divider_positions.each do |divider_x|
        draw_divider_trapezoid(args, divider_x, world_y, divider_length,
                               divider_width_start, divider_width_end)
      end

      world_y += divider_spacing
    end
  end

  def draw_divider_trapezoid(args, divider_x, world_y, divider_length, width_start, width_end)
    # Get screen positions for near and far ends of the divider
    divider_start = @camera.world_to_screen(divider_x, world_y)
    divider_end = @camera.world_to_screen(divider_x, world_y + divider_length)

    # Calculate the four corners of the trapezoid
    bottom_left_x = divider_start.x - width_start / 2
    bottom_right_x = divider_start.x + width_start / 2
    bottom_y = divider_start.y
    
    top_left_x = divider_end.x - width_end / 2
    top_right_x = divider_end.x + width_end / 2
    top_y = divider_end.y

    # Draw the trapezoid by filling with interpolated horizontal lines
    num_fill_lines = [((top_y - bottom_y).abs / 2).to_i, 1].max
    
    num_fill_lines.times do |i|
      t = i.to_f / num_fill_lines
      
      line_y = bottom_y + (top_y - bottom_y) * t
      line_left_x = bottom_left_x + (top_left_x - bottom_left_x) * t
      line_right_x = bottom_right_x + (top_right_x - bottom_right_x) * t
      line_width = line_right_x - line_left_x
      
      args.outputs.solids << {
        x: line_left_x,
        y: line_y,
        w: line_width,
        h: 2,
        r: Config::LANE_DIVIDER_COLOR[:r],
        g: Config::LANE_DIVIDER_COLOR[:g],
        b: Config::LANE_DIVIDER_COLOR[:b],
        a: 200
      }
    end
  end

  def draw_road_edges(args)
    # Draw road edges as borders along the road trapezoid
    # Draw them as part of the road surface using horizontal line segments
    # This makes them follow the perspective correctly

    # Get the four corners of the road trapezoid
    near_left = @camera.world_to_screen(Config::ROAD_MIN_X, 0)
    near_right = @camera.world_to_screen(Config::ROAD_MAX_X, 0)
    far_left = @camera.world_to_screen(Config::ROAD_MIN_X, @camera.world_depth)
    far_right = @camera.world_to_screen(Config::ROAD_MAX_X, @camera.world_depth)

    # Calculate total height of road on screen
    road_height = far_left[:y] - near_left[:y]

    # Draw edges as thick lines along the left and right sides
    # Use many small segments to follow the perspective curve
    num_segments = (road_height / 2).ceil
    edge_thickness = 3

    num_segments.times do |i|
      t = i.to_f / num_segments

      # Calculate Y position
      y = near_left[:y] + (far_left[:y] - near_left[:y]) * t

      # Calculate X positions for left and right edges
      left_x = near_left[:x] + (far_left[:x] - near_left[:x]) * t
      right_x = near_right[:x] + (far_right[:x] - near_right[:x]) * t

      # Draw left edge segment
      args.outputs.solids << {
        x: left_x - edge_thickness,
        y: y,
        w: edge_thickness,
        h: 3,
        r: Config::ROAD_EDGE_COLOR[:r],
        g: Config::ROAD_EDGE_COLOR[:g],
        b: Config::ROAD_EDGE_COLOR[:b],
        a: 255
      }

      # Draw right edge segment
      args.outputs.solids << {
        x: right_x,
        y: y,
        w: edge_thickness,
        h: 3,
        r: Config::ROAD_EDGE_COLOR[:r],
        g: Config::ROAD_EDGE_COLOR[:g],
        b: Config::ROAD_EDGE_COLOR[:b],
        a: 255
      }
    end
  end
end
```

## File: app/rendering/ui_renderer.rb
```ruby
# UI/HUD rendering system
class UIRenderer
  def render_hud(args, score, distance, speed)
    # Score
    args.outputs.labels << {
      x: 40,
      y: Config::SCREEN_HEIGHT - 40,
      text: "Score: #{score}",
      size_enum: Config::UI_FONT_SIZE,
      r: Config::UI_TEXT_COLOR[:r],
      g: Config::UI_TEXT_COLOR[:g],
      b: Config::UI_TEXT_COLOR[:b]
    }

    # Distance
    args.outputs.labels << {
      x: 40,
      y: Config::SCREEN_HEIGHT - 80,
      text: "Distance: #{distance.to_i}",
      size_enum: Config::UI_FONT_SIZE,
      r: Config::UI_TEXT_COLOR[:r],
      g: Config::UI_TEXT_COLOR[:g],
      b: Config::UI_TEXT_COLOR[:b]
    }

    # Speed
    args.outputs.labels << {
      x: 40,
      y: Config::SCREEN_HEIGHT - 120,
      text: "Speed: #{speed.round(1)}",
      size_enum: Config::UI_FONT_SIZE,
      r: Config::UI_TEXT_COLOR[:r],
      g: Config::UI_TEXT_COLOR[:g],
      b: Config::UI_TEXT_COLOR[:b]
    }
  end

  def render_game_over(args, score, distance)
    # Game over background
    args.outputs.solids << {
      x: 0,
      y: 0,
      w: Config::SCREEN_WIDTH,
      h: Config::SCREEN_HEIGHT,
      r: 0,
      g: 0,
      b: 0,
      a: 180
    }

    # Game over text
    args.outputs.labels << {
      x: Config::SCREEN_WIDTH / 2,
      y: Config::SCREEN_HEIGHT / 2 + 100,
      text: "GAME OVER",
      size_enum: Config::GAME_OVER_FONT_SIZE,
      alignment_enum: 1,
      r: 255,
      g: 50,
      b: 50
    }

    # Final score
    args.outputs.labels << {
      x: Config::SCREEN_WIDTH / 2,
      y: Config::SCREEN_HEIGHT / 2,
      text: "Final Score: #{score}",
      size_enum: Config::UI_FONT_SIZE,
      alignment_enum: 1,
      r: Config::UI_TEXT_COLOR[:r],
      g: Config::UI_TEXT_COLOR[:g],
      b: Config::UI_TEXT_COLOR[:b]
    }

    # Final distance
    args.outputs.labels << {
      x: Config::SCREEN_WIDTH / 2,
      y: Config::SCREEN_HEIGHT / 2 - 50,
      text: "Distance: #{distance.to_i}",
      size_enum: Config::UI_FONT_SIZE,
      alignment_enum: 1,
      r: Config::UI_TEXT_COLOR[:r],
      g: Config::UI_TEXT_COLOR[:g],
      b: Config::UI_TEXT_COLOR[:b]
    }

    # Restart instruction
    args.outputs.labels << {
      x: Config::SCREEN_WIDTH / 2,
      y: Config::SCREEN_HEIGHT / 2 - 150,
      text: "Press R to Restart",
      size_enum: Config::UI_FONT_SIZE,
      alignment_enum: 1,
      r: 200,
      g: 200,
      b: 200
    }
  end
end
```

## File: app/systems/collision_detector.rb
```ruby
# Collision detection system
class CollisionDetector
  def check_collisions(game_state)
    player = game_state.player
    player_bounds = player.bounds

    # Check obstacle collisions
    game_state.obstacles.each do |obstacle|
      if boxes_overlap?(player_bounds, obstacle.bounds)
        player.hit_obstacle
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
```

## File: app/systems/input_handler.rb
```ruby
# Input handling system
class InputHandler
  def process(args, game_state)
    # Handle restart (check this BEFORE early return)
    if game_state.game_over && args.inputs.keyboard.key_down.r
      game_state.reset
      return
    end

    # Don't process game controls if game is over
    return if game_state.game_over

    player = game_state.player

    # Handle continuous horizontal movement with arrow keys or A/D
    # Check if keys are held down (not just pressed)
    if args.inputs.keyboard.left || args.inputs.keyboard.a
      player.move_left
    elsif args.inputs.keyboard.right || args.inputs.keyboard.d
      player.move_right
    else
      # Stop moving when no keys are pressed
      player.stop_horizontal_movement
    end
  end
end
```

## File: app/systems/spawner.rb
```ruby
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
```

## File: app/game_state.rb
```ruby
# Game state management
class GameState
  attr_accessor :player, :obstacles, :coins, :score, :distance, :game_over, :road_offset

  def initialize
    @player = Player.new
    @obstacles = []
    @coins = []
    @score = 0
    @distance = 0
    @road_offset = 0  # Tracks road animation at same speed as objects
    @game_over = false
  end

  def update
    # Update distance based on player speed (for score display)
    @distance += @player.speed * Config::DISTANCE_MULTIPLIER

    # Update road offset at constant world-space speed (same as objects)
    # Both road markings and objects move at constant speed in world space
    # The perspective projection makes them appear to accelerate on screen
    @road_offset += @player.speed

    # Update player
    @player.update

    # Update obstacles
    @obstacles.each { |obs| obs.update(@player.speed) }
    @obstacles.reject! { |obs| obs.off_screen? }

    # Update coins
    @coins.each { |coin| coin.update(@player.speed) }
    @coins.reject! { |coin| coin.off_screen? }

    # Check game over condition
    if @player.game_over?
      @game_over = true
    end
  end

  def reset
    @player.reset
    @obstacles.clear
    @coins.clear
    @score = 0
    @distance = 0
    @road_offset = 0
    @game_over = false
  end
end
```

## File: app/game.rb
```ruby
# Main game class - orchestrates all systems
class Game
  def initialize
    @game_state = GameState.new
    @renderer = Renderer.new
    @input_handler = InputHandler.new
    @collision_detector = CollisionDetector.new
    @spawner = Spawner.new
  end

  def tick(args)
    # Process input
    @input_handler.process(args, @game_state)

    # Don't update game logic if game is over
    unless @game_state.game_over
      # Update game state
      @game_state.update

      # Spawn new entities
      @spawner.update(@game_state)

      # Check collisions
      @collision_detector.check_collisions(@game_state)
    end

    # Render everything
    @renderer.render(args, @game_state)
  end
end
```

## File: app/main.rb
```ruby
# Endless Runner Game - Isometric Perspective
# Refactored with clean OOP architecture
#
# Project Structure:
# - config/constants.rb      : Game configuration and constants
# - entities/                : Game entities (Player, Obstacle, Coin)
# - systems/                 : Game systems (InputHandler, CollisionDetector, Spawner)
# - rendering/               : Rendering systems (Renderer, PerspectiveCamera, RoadRenderer, UIRenderer)
# - game_state.rb            : Game state management
# - game.rb                  : Main game orchestrator

# Require all dependencies
require 'app/config/constants.rb'
require 'app/entities/player.rb'
require 'app/entities/obstacle.rb'
require 'app/entities/coin.rb'
require 'app/systems/input_handler.rb'
require 'app/systems/collision_detector.rb'
require 'app/systems/spawner.rb'
require 'app/rendering/perspective_camera.rb'
require 'app/rendering/road_renderer.rb'
require 'app/rendering/ui_renderer.rb'
require 'app/rendering/renderer.rb'
require 'app/game_state.rb'
require 'app/game.rb'

# Main game loop - DragonRuby entry point
def tick(args)
  # Initialize game instance on first tick
  args.state.game ||= Game.new

  # Run game tick
  args.state.game.tick(args)
end
```

## File: README.md
```markdown
# Endless Runner Game - Isometric Edition

A simple endless runner game inspired by Subway Surfers with an isometric/pseudo-3D perspective similar to Diablo-like games, built with DragonRuby Game Toolkit.

## How to Run

1. Copy the `test-first-game` folder to your DragonRuby GTK installation directory
2. Run DragonRuby and select the `test-first-game` folder
3. Or run from command line: `./dragonruby test-first-game`

## Controls

- **Arrow Keys** or **A/D Keys**: Move left/right between lanes
- **R Key**: Restart game (when game over)

## Gameplay

- Your character automatically runs forward at a constant speed
- Switch between 3 lanes to avoid obstacles and collect coins
- **Obstacles (Red Buses)**: Hitting them reduces your speed significantly
- **Coins (Gold Squares)**: Collecting them increases your score and boosts speed
- **Speed Decay**: Your speed gradually decreases over time
- **Game Over**: When your speed drops too low, the police catch you!

## Visual Features

- **Isometric Perspective**: Top-down angled view similar to Diablo, Path of Exile, and classic isometric RPGs
- **Depth Perception**: Objects appear smaller as they get further away (higher on screen)
- **Converging Lanes**: Road lanes converge toward a vanishing point to create 3D depth
- **Perspective Scaling**: All game objects scale based on their distance from the camera
- **Player**: Blue rectangle at the bottom-center, viewed from a 45-degree angle
- **Obstacles**: Red rectangles (buses) that appear in the distance and approach the player
- **Coins**: Gold squares that spawn far away and move toward the player
- **Road**: Three lanes with animated dividers that create a sense of movement and depth

## Scoring

- Distance traveled = Base score
- Each coin collected = +10 points
- Try to survive as long as possible!

## Tips

- Collect coins to maintain your speed
- Avoid obstacles to prevent speed loss
- Plan your lane switches ahead of time
- Watch the speed bar - don't let it get too low!
- Objects in the distance appear smaller - use this visual cue to plan ahead!
```
