class Platform
  attr_accessor :x, :y, :w, :h, :path

  def rect
    {
      x: x,
      y: y,
      w: w,
      h: h + 10,
    }
  end

  def prefab
    {
      x: x,
      y: y,
      w: w,
      h: h,
      path: path,
    }
  end

  def initialize(param)
    @x = param.x
    @y = param.y
    @w = param.w
    @h = param.h
    @path = param.path
  end
end

class PlatformSpawner
  attr_reader :platforms

  def initialize
    @platforms = []
    @last_spawn_at = 0
    @spawn_interval = 2.seconds

    @difficulty_mul = 1
  end

  def tick

    if Kernel.tick_count % 30.seconds == 0
      @difficulty_mul += 0.1 # TODO?
    end

    if @spawn_interval < Kernel.tick_count - @last_spawn_at
      @last_spawn_at = Kernel.tick_count
      @spawn_interval = Numeric.rand(1.seconds..80) * 1 / @difficulty_mul

      spawn_left = [true, false].sample
      spawn_right = [true, false].sample

      typed_param = case Numeric.rand(0..1)
                    when 0
                      { w: 240, h: 80, path: "sprites/platform_2.png" }
                    when 1
                      { w: 400, h: 80, path: "sprites/platform_4.png" }
                    when 2
                      { w: 80, h: 80, path: "sprites/platform_2.png" }

                    end
      if spawn_left
        @platforms << Platform.new({ x: Numeric.rand(50..500), y: Numeric.rand(750..800) }.merge(typed_param))
      end
      if spawn_right
        @platforms << Platform.new({ x: Numeric.rand(500..1200), y: Numeric.rand(750..800) }.merge(typed_param))
      end

      if !spawn_left && !spawn_right
        @platforms << Platform.new({ x: Numeric.rand(50..1200), y: Numeric.rand(750..800) }.merge(typed_param))
      end
    end

    @platforms.each do |platform|
      platform.y -= 3 * @difficulty_mul

      if platform.y < -76
        @platforms.delete(platform)
      end
    end
  end

end