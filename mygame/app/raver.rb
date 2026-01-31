$spring_x = Spring.new(0.3, 0.6)
$spring_y = Spring.new(0.35, 0.55)

class Raver
  attr_accessor :x, :y, :target, :velocity_y, :velocity_x

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
      y: y,
      w: 100,
      h: 100,
      path: :solid,
    }
  end

  def initialize(target:, x: 0, y: 0)
    @target = target
    @x = x
    @y = y
    @velocity_x = 0
    @velocity_y = 0

  end

  def tick
    return if @target.nil?

    sx = $spring_x.spring(@target.x, @x, @velocity_x, 1)
    @x = sx.d
    @velocity_x = sx.v / 2

    sy = $spring_y.spring(@target.y + 100, @y, @velocity_y, 1)
    @y = sy.d
    @velocity_y = sy.v / 2
  end

  def follow(target:)
    @target = target
  end
end

# noinspection RubyNilAnalysis
class Friends
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

    @ravers = [Raver.new(target: nil)]
  end

  def tick
    return if head_raver.nil?

    unless @is_flying
      head_raver.velocity_x *= 0.9
    end

    head_raver.velocity_y += -0.5 # gravity

    head_raver.x += head_raver.velocity_x
    head_raver.y += head_raver.velocity_y

    head_raver.x = head_raver.x.clamp(0, 900)
    head_raver.y = head_raver.y.clamp(@min_y, 720)

    @is_on_ground = head_raver.y == @min_y
    @is_flying = head_raver.y > @min_y
    @is_falling = head_raver.velocity_y < 0 && head_raver.y > @min_y

    @ravers.each do |raver|
      raver.tick
    end
  end

  # todo: improve!
  def find_raver_closest_to(position)
    return nil if ravers.empty?

    ravers.map { |raver|
      {
        distance: Geometry.distance(raver, position),
        raver: raver,
      }
    }.min_by { |raver| raver.distance }.raver
  end

  def add_new_raver(new_raver)
    closest_raver = find_raver_closest_to(new_raver)

    if closest_raver.nil?
      # no raver exist
      @ravers << new_raver
      return
    end

    # who is following our closest raver
    closest_raver_follower = ravers.find { |raver| raver.target == closest_raver }

    if closest_raver_follower
      # follow the new raver
      closest_raver_follower.target = new_raver
    end

    new_raver.target = closest_raver

    @ravers << new_raver
  end

  def remove_raver_closest_to(position)
    closest_raver = find_raver_closest_to(position)

    # who is following our closest raver
    closest_raver_follower = ravers.find { |raver| raver.target == closest_raver }
    # who our closest raver is following
    closest_raver_target = closest_raver.target

    if closest_raver_follower
      # follow the new raver
      closest_raver_follower.target = closest_raver_target
    end

    @ravers.delete(closest_raver)
  end

  def jump
    head_raver.velocity_y = 20
  end

  # TODO: fix this up?
  def move_left(speed: 1)
    coef = if @is_flying
             0.2
           else
             5
           end
    head_raver.velocity_x -= speed * coef
    head_raver.velocity_x = head_raver.velocity_x.greater(-10)
  end

  def move_right(speed: 1)
    coef = if @is_flying
             0.2
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
