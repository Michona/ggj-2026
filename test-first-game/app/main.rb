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