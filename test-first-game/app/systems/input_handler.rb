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

    # Handle lane switching with arrow keys or A/D
    if args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_down.a
      player.move_left
    elsif args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_down.d
      player.move_right
    end
  end
end

