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

