require 'app/laurence_main'
require 'app/raver'

class Platform
  attr_accessor :x, :y, :w, :h, :path

  def rect
    {
      x: x,
      y: y,
      w: w,
      h: h,
      path: path,
    }
  end

  def initialize(x:, y:, w:, path:)
    @x = x
    @y = y
    @w = w
    @h = 100
    @path = path
  end
end

def local_tick(args)
  if Kernel.tick_count == 0
    $friends = Friends.new
    $platforms = []
  end

  if args.inputs.keyboard.space && !$friends.is_flying
    $friends.jump
  end

  if args.inputs.keyboard.a
    $friends.move_left
  end

  if args.inputs.keyboard.d
    $friends.move_right
  end

  if Kernel.tick_count % 200 == 0
    $friends.add_new_raver Raver.new(target: nil, x: 200, y: 200)
  end

  if Kernel.tick_count % 500 == 0
    $friends.remove_raver_closest_to({ x: 200, y: 200 })
  end

  # Check collision
  args.outputs.debug.watch $friends.is_flying
  args.outputs.debug.watch $friends.is_falling

  $friends.tick


  # TODO: move colliding logic away
  colliding_platform = Geometry.find_intersect_rect($friends.head_raver.rect, $platforms, using: :rect)
  if colliding_platform && ($friends.is_falling || $friends.is_on_ground) &&
     $friends.y >= (colliding_platform.y + colliding_platform.h - 10)

    $friends.collide_with_platform(platform_y: colliding_platform.y + colliding_platform.h - 4)
  else
    $friends.collide_with_platform(platform_y: 0)
  end

  if Kernel.tick_count % 200 == 0
    $platforms << Platform.new(x: Numeric.rand(100..1000), y: 700, w: 300, path: :solid)
  end

  # RENDER

  args.outputs.background_color = [66, 191, 245]
  $friends.prefabs.each do |prefab|
    args.outputs.sprites << prefab
  end
  $platforms.each do |p|
    # p.y -= 2
    args.outputs.sprites << p.rect
  end
end

def tick(args)
  # laurence_tick(args)
  local_tick(args)
end
