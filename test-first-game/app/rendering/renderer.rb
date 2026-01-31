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
    # 2. Lane dividers (on road)
    # 3. Game objects (player, obstacles, coins) in depth order
    # 4. Road edges (lines on top for visual clarity)
    # 5. UI (always on top)

    # Draw road (use road_offset which moves at same speed as objects)
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

