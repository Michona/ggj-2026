# Main rendering orchestrator
class Renderer
  def initialize
    @camera = PerspectiveCamera.new
    @road_renderer = RoadRenderer.new(@camera)
    @ui_renderer = UIRenderer.new
  end

  def render(args, game_state)
    # Update camera (for shake effect)
    @camera.update

    # Background color (darker for depth)
    args.outputs.background_color = [15, 20, 25]

    # RENDER ORDER:
    # 1. Road surface (background)
    # 2. Road edges (lines under everything)
    # 3. Lane dividers (on road)
    # 4. Game objects (player, obstacles, coins) in depth order - should be ON TOP of road edges
    # 5. Horizon fog (fade in effect)
    # 6. UI (always on top)

    # Draw road (use road_offset which moves at same speed as objects)
    # Road edges are drawn first so objects appear on top of them
    # Pass player speed for dynamic road line animation
    @road_renderer.render(args, game_state.road_offset, game_state.player.speed)

    # Draw game objects in depth order
    render_game_objects(args, game_state)

    # Draw horizon fog
    render_horizon_fog(args)

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
    shadow_objects = []

    # Add obstacles
    game_state.obstacles.each do |obs|
      screen_rect = @camera.world_rect_to_screen(obs.x, obs.y, obs.w, obs.h)
      render_objects << {
        depth: obs.y,
        type: :obstacle,
        primitive: {
          x: screen_rect[:x],
          y: screen_rect[:y],
          w: screen_rect[:w],
          h: screen_rect[:h],
          path: :pixel,  # Use pixel for solid color rendering
          r: obs.color[:r],
          g: obs.color[:g],
          b: obs.color[:b]
        }
      }

      # Add shadow for obstacle
      shadow_objects << create_shadow(obs.x, obs.y, obs.w, screen_rect[:scale])
    end

    # Add coins
    game_state.coins.each do |coin|
      screen_rect = @camera.world_rect_to_screen(coin.x, coin.y, coin.w, coin.h)
      render_objects << {
        depth: coin.y,
        type: :coin,
        primitive: {
          x: screen_rect[:x],
          y: screen_rect[:y],
          w: screen_rect[:w],
          h: screen_rect[:h],
          path: :pixel,  # Use pixel for solid color rendering
          r: coin.color[:r],
          g: coin.color[:g],
          b: coin.color[:b]
        }
      }

      # Add shadow for coin
      shadow_objects << create_shadow(coin.x, coin.y, coin.w, screen_rect[:scale])
    end

    # Add player (with lean animation)
    player = game_state.player
    screen_rect = @camera.world_rect_to_screen(player.x, player.y, player.w, player.h)
    render_objects << {
      depth: player.y,
      type: :player,
      primitive: {
        x: screen_rect[:x],
        y: screen_rect[:y],
        w: screen_rect[:w],
        h: screen_rect[:h],
        path: :pixel,  # Use pixel for solid color rendering
        r: player.color[:r],
        g: player.color[:g],
        b: player.color[:b],
        angle: player.lean_angle,  # Apply lean rotation
        anchor_x: 0.5,  # Rotate around center
        anchor_y: 0.5
      }
    }

    # Add shadow for player
    shadow_objects << create_shadow(player.x, player.y, player.w, screen_rect[:scale])

    # Sort by depth (render far objects first), with secondary sort by type to prevent z-fighting
    render_objects = render_objects.sort_by { |obj| [-obj[:depth], obj[:type].to_s] }

    # Render shadows first (they should be under everything)
    shadow_objects.each do |shadow|
      args.outputs.sprites << shadow
    end

    # Render all objects in depth order
    render_objects.each do |obj|
      args.outputs.sprites << obj[:primitive]
    end
  end

  def create_shadow(world_x, world_y, object_width, scale)
    # Shadow is an ellipse at the base of the object
    # Position shadow slightly behind the object (at y=0, the ground level)
    shadow_pos = @camera.world_to_screen(world_x, 0)

    # Shadow size scales with object and perspective
    shadow_width = object_width * scale * 1.2  # Slightly wider than object
    shadow_height = shadow_width * 0.3  # Ellipse is flattened

    # Shadow opacity decreases with distance (objects further away have fainter shadows)
    shadow_alpha = (scale * 100).to_i
    shadow_alpha = [[shadow_alpha, 30].max, 100].min

    {
      x: shadow_pos[:x] - shadow_width / 2,
      y: shadow_pos[:y] - shadow_height / 2,
      w: shadow_width,
      h: shadow_height,
      r: 0,
      g: 0,
      b: 0,
      a: shadow_alpha,
      path: :pixel  # Use pixel primitive for solid color
    }
  end

  def render_horizon_fog(args)
    # Draw gradient fog over top 20% of screen
    # This makes objects fade in smoothly instead of popping into existence
    fog_height = Config::SCREEN_HEIGHT * 0.20
    fog_start_y = Config::SCREEN_HEIGHT - fog_height

    # Draw multiple horizontal strips with increasing opacity
    num_strips = 20
    num_strips.times do |i|
      # Calculate position and opacity for this strip
      # Top strips are opaque, bottom strips are transparent
      t = i.to_f / num_strips
      strip_y = fog_start_y + (fog_height * t)
      strip_alpha = ((1.0 - t) * 180).to_i  # Fade from 180 to 0

      args.outputs.sprites << {
        x: 0,
        y: strip_y,
        w: Config::SCREEN_WIDTH,
        h: (fog_height / num_strips) + 1,  # Slight overlap to prevent gaps
        path: :pixel,
        r: 15,  # Match background color
        g: 20,
        b: 25,
        a: strip_alpha
      }
    end
  end

  attr_reader :camera
end

