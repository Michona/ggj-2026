class LoneRaver
  attr_accessor :x, :y, :can_be_snatched, :type, :w, :h
  include Animatable

  def prefab
    {
      x: x,
      y: y,
      w: w,
      h: h,
      path: "sprites/#{type.to_s}_front_#{sprite_id}.png",
    }
  end

  def cloud_prefab
    {
      x: x - 40,
      y: y - 60,
      w: 200,
      h: 100,
      path: "sprites/cloud.png",
    }
  end

  def initialize(x:, y:, w: 120, h: 120, type:)
    @x = x
    @y = y
    @h = h
    @w = w
    @type = type
    @can_be_snatched = false
    @animation_speed = 4
  end

  def create_raver
    Raver.new(target: nil, x: x, y: y, type: @type)
  end

  def update_can_be_snatched(raver_positions:)
     @can_be_snatched = raver_positions.map { |pos|
      Geometry.distance(pos, self)
    }.min < 100
  end
end

class LoneRaverSpawner
  # dependency on RaverGroup

  attr_reader :lone_ravers

  def initialize
    @lone_ravers = []

    @last_spawn_at = 0
    @spawn_interval = 3.seconds
  end

  def tick
    if @spawn_interval < Kernel.tick_count - @last_spawn_at
      @last_spawn_at = Kernel.tick_count
      @lone_ravers << LoneRaver.new(x: Numeric.rand(100..1000), y: 800, type: RAVER_TYPES.sample)
    end

    lone_ravers.each do |lone_raver|
      lone_raver.update_can_be_snatched(raver_positions: $raver_group.ravers)

      lone_raver.y -= 1
      if lone_raver.y < 0
        @lone_ravers.delete(lone_raver)
      end
    end
  end

  # Picked up by the raver group
  def pick_up(lone_raver)
    @lone_ravers.delete(lone_raver)
  end

  private
end