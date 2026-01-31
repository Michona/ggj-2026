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

