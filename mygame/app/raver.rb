$spring_x = Spring.new(0.3, 0.3, 0.6, 0.6)
$spring_y = Spring.new(0.35, 0.35, 0.55, 0.55)

RAVER_TYPES = [:elephant, :rabbit, :shrimp, :mouse, :bird, :dog, :cat]

class Raver
  attr_accessor :x, :y, :target, :velocity_y, :velocity_x, :type

  include Animatable

  def rect
    {
      x: x,
      y: y,
      w: 100,
      h: 100,
    }
  end

  def prefab
    {
      x: x,
      y: y - 20,
      w: 140,
      h: 140,
      path: "sprites/#{type}_back_#{sprite_id}.png",
    }
  end

  def index
    if target.nil?
      0
    else
      target.index + 1
    end
  end

  def initialize(target:, type:, x: 0, y: 0)
    @target = target
    @type = type
    @x = x
    @y = y
    @velocity_x = 0
    @velocity_y = 0
  end

  def tick
    return if @target.nil?

    sx = $spring_x.spring(@target.x, @x, @velocity_x, index)
    @x = sx.d
    @velocity_x = sx.v

    sy = $spring_y.spring(@target.y + 100, @y, @velocity_y, index)
    @y = sy.d
    @velocity_y = sy.v
  end

  def follow(target)
    @target = target
    @velocity_x = 0
    @velocity_y = 0
  end
end

# noinspection RubyNilAnalysis
class RaverGroup
  attr_accessor :is_flying # TODO: ?
  attr_accessor :is_falling
  attr_accessor :is_on_ground

  attr_reader :ravers

  def rects
    ravers.map { |raver| raver.rect }
  end

  def prefabs
    ravers.map { |raver| raver.prefab }
  end

  # TODO: has to be only one
  def head_raver
    ravers.find { |raver| raver.target.nil? }
  end
  
  def x
    head_raver.x
  end

  def y
    head_raver.y
  end

  def initialize
    @min_y = 0
    @is_flying = false
    @is_falling = false
    @is_on_ground = true

    @ravers = [Raver.new(target: nil, type: :rabbit)]
  end

  def tick
    return if head_raver.nil?

    head_raver.velocity_x *= 0.9
    # unless @is_flying
    #   head_raver.velocity_x *= 0.9
    # end

    head_raver.velocity_y += -0.9 # gravity
    head_raver.velocity_y = head_raver.velocity_y.greater(-15) # TODO: maybe?

    head_raver.x += head_raver.velocity_x
    head_raver.y += head_raver.velocity_y

    head_raver.x = head_raver.x.clamp(0, 1200)
    head_raver.y = head_raver.y.clamp(@min_y, 720)

    @is_on_ground = head_raver.y == @min_y
    @is_flying = head_raver.y > @min_y
    @is_falling = head_raver.velocity_y < 0 && head_raver.y > @min_y

    @ravers.each do |raver|
      raver.tick

      # update animation states
      if is_flying
        raver.animation_speed = 4
      else
        raver.animation_speed = 0
      end
    end

    if is_on_ground && head_raver.velocity_x.abs > 0.5
      head_raver.animation_speed = 8
    end

    $score.highest_stack = [$score.highest_stack, @ravers.size].max
  end

  def find_raver_closest_to(position)
    return nil if ravers.empty?

    ravers.min_by { |raver|
       Geometry.distance(raver, position)
    }
  end

  def add_new_raver(new_raver)
    closest_raver = find_raver_closest_to(new_raver)

    if closest_raver.nil?
      # no raver exist
      @ravers << new_raver
      return
    end

    # who is following our closest raver
    closest_raver_follower = follower_of closest_raver

    if closest_raver_follower
      # follow the new raver
      closest_raver_follower.target = new_raver
    end

    new_raver.target = closest_raver

    @ravers << new_raver
  end

  def remove_raver_closest_to(position)
    remove_raver(find_raver_closest_to(position))
  end

  def remove_raver_with_type(type)
    raver_to_remove = ravers.find { |raver| raver.type == type }
    if raver_to_remove
      remove_raver(raver_to_remove)
    end
  end

  def remove_raver(raver_to_remove)
    return if ravers.size == 1 # TODO:?

    # who is following our closest raver
    raver_to_remove_follower = follower_of raver_to_remove
    # who our closest raver is following
    raver_to_remove_target = raver_to_remove.target

    if raver_to_remove_follower
      # follow the new raver
      raver_to_remove_follower.follow raver_to_remove_target
    end

    @ravers.delete(raver_to_remove)
  end

  def remove_head
    remove_raver(head_raver)
  end

  def follower_of(raver)
    # TODO: optimize this, cuz its ridiculus - maybe double linked list
    ravers.find { |r| r.target == raver }
  end

  def switch
    # TODO:
  end

  def jump
    head_raver.velocity_y = 26
  end

  # TODO: fix this up?
  def move_left(speed: 1)
    coef = if @is_flying
             0.7
           else
             5
           end
    head_raver.velocity_x -= speed * coef
    head_raver.velocity_x = head_raver.velocity_x.greater(-10)
  end

  def move_right(speed: 1)
    coef = if @is_flying
             0.7
           else
             5
           end

    head_raver.velocity_x += speed * coef
    head_raver.velocity_x = head_raver.velocity_x.lesser(10)
  end

  def collide_with_platform(platform_y:)
    @min_y = platform_y
  end
end
