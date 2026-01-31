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

