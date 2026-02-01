require 'app/animatable'
require 'app/laurence_main'
require 'app/raver'
require 'app/platform'
require 'app/lone_raver'
require 'app/window'
require 'app/background'
require 'app/score'
require 'app/coin'
require 'app/rave'

def setup
  $raver_group = RaverGroup.new
  $platform_spawner = PlatformSpawner.new
  $lone_raver_spawner = LoneRaverSpawner.new
  $window_spawner = WindowSpawner.new
  $background_spawner = BackgroundSpawner.new
  $coin_spawner = CoinSpawner.new
  $score = Score.new
end

def tick_game(args)
  if (args.inputs.keyboard.space || args.state.controller.a) && !$raver_group.is_flying
    $raver_group.jump
  end

  if args.inputs.left
    $raver_group.move_left
  end

  if args.inputs.right
    $raver_group.move_right
  end

  if args.inputs.keyboard.j || args.state.controller.b
    $lone_raver_spawner.lone_ravers.each do |lone_raver|
      if lone_raver.can_be_snatched
        $raver_group.add_new_raver lone_raver.create_raver
        $lone_raver_spawner.pick_up(lone_raver)
      end
    end
  end

  if args.inputs.keyboard.k || args.state.controller.x
    $window_spawner.windows.each do |window|
      if window.can_be_opened
        window.types.each do |type|
          $raver_group.remove_raver_with_type(type)
        end
        $window_spawner.close_window(window)
        break
      end
    end
  end

  $raver_group.tick
  $platform_spawner.tick
  $lone_raver_spawner.tick
  $window_spawner.tick
  $background_spawner.tick
  $coin_spawner.tick

  # COLLISION with platform
  colliding_platform = Geometry.find_intersect_rect($raver_group.head_raver.rect, $platform_spawner.platforms, using: :rect)
  if colliding_platform && ($raver_group.is_falling || $raver_group.is_on_ground) &&
     $raver_group.y >= (colliding_platform.y + colliding_platform.h - 20)
    $raver_group.collide_with_platform(platform_y: colliding_platform.y + colliding_platform.h - 4)
  else
    if $raver_group.y < 10 && $raver_group.ravers.size > 1
      $raver_group.remove_head
      $raver_group.jump
    end
    $raver_group.collide_with_platform(platform_y: 0)
  end

  # RENDER
  $background_spawner.backgrounds.each do |background|
    args.outputs.sprites << background.prefab
  end
  $platform_spawner.platforms.each do |platform|
    args.outputs.sprites << platform.prefab
  end

  $window_spawner.windows.each do |window|
    args.outputs.sprites << window.prefab
    args.outputs.sprites << window.indicator_prefabs
  end

  $lone_raver_spawner.lone_ravers.each do |lone_raver|
    args.outputs.sprites << lone_raver.cloud_prefab
    args.outputs.sprites << lone_raver.prefab
  end
  $coin_spawner.coins.each do |coin|
    args.outputs.sprites << coin.prefab
  end

  $raver_group.prefabs.each do |prefab|
    args.outputs.sprites << prefab
  end

  # LABELS
  args.outputs.labels << {
    x: 50,
    y: 700,
    text: "Score: #{$score.points}",
    font: "fonts/font.otf"

  }
  args.outputs.labels << {
    x: 50,
    y: 650,
    text: "Windows: #{$score.windows_missed} of #{$score.max_windows}",
    font: "fonts/font.otf"

  }
  args.outputs.labels << {
    x: 50,
    y: 600,
    text: "Highest stack: #{$score.highest_stack}",
    font: "fonts/font.otf"

  }
end

def tick_start_screen(args)
  args.outputs.background_color = [0, 0, 0]
  args.outputs.sprites << $rave.prefab
  args.outputs.labels << {
    x: 640,
    y: 60,
    anchor_x: 0.5,
    text: "Press Enter to RAVE!",
    font: "fonts/font.otf"
  }
  args.outputs.labels << {
    x: 640,
    y: 40,
    anchor_x: 0.5,
    text: "Space to jump, J to collect your friend, K to drop off",
    font: "fonts/font.otf"
  }
end

def tick_end_screen(args)
  args.outputs.background_color = [0, 0, 0]
  args.outputs.sprites << $rave.prefab
  $sample_ravers.each do |sample_raver|
    args.outputs.sprites << sample_raver.prefab
  end
  args.outputs.labels << {
    x: 100,
    y: 50,
    text: "Score: #{$score.points}",
    font: "fonts/font.otf"
  }
  args.outputs.labels << {
    x: 300,
    y: 50,
    text: "Highest stack: #{$score.highest_stack}",
    font: "fonts/font.otf"
  }
end

def tick(args)
  if Kernel.tick_count == 0
    Numeric.srand(1769947109)

    unless GTK.platform? :web
      GTK.set_window_fullscreen true
    end

    mk_music(args)
    $scene = :scene_loading
    $rave = Rave.new

    $sample_ravers = []
    (1..20).each do |i|
      $sample_ravers << LoneRaver.new(x: [Numeric.rand(45..55) * i, 1280].min, y: Numeric.rand(40..60), w: 200, h: 200, type: RAVER_TYPES.sample)
    end
  end

  args.state.controller ||= args.inputs.controller_one

  if (args.inputs.keyboard.enter || args.state.controller.a) && ($scene == :scene_loading || $scene == :scene_end)
    $scene = :scene_game
    setup
  end

  case $scene
  when :scene_loading
    tick_start_screen(args)

  when :scene_game
    tick_game(args)

    if $score.has_died?
      $scene = :scene_end
    end

  when :scene_end
    tick_end_screen(args)
  end
end
