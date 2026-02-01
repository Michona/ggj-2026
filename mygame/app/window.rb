class Window
  attr_accessor :x, :y, :can_be_opened

  def prefab
    {
      x: x,
      y: y,
      w: w,
      h: h,
      path: "sprites/window_#{@sprite_id}.png",
    }
  end

  def h
    if can_be_opened
      110
    else
      100
    end
  end

  def w
    if can_be_opened
      220
    else
      200
    end
  end

  def types
    @accepted_types
  end

  def indicator_prefabs
    indicator_size = 70
    @accepted_types.each_with_index.map do |type, index|
      delta = if x < 500
                -indicator_size * 0.6 * index
              else
                w + -indicator_size + indicator_size * 0.6 * index
              end

      {
        x: x + delta,
        y: y,
        w: indicator_size,
        h: indicator_size,
        path: "sprites/#{type}_front_0.png"
      }
    end
  end

  def rect
    {
      x: x,
      y: y,
      w: 100,
      h: 100,
    }
  end

  def initialize(x:, y:, accepted_types:)
    @x = x
    @y = y
    @accepted_types = accepted_types
    @can_be_opened = false
    @sprite_id = Numeric.rand(0..4)
  end

  def update_can_be_opened(raver_group:)
    @can_be_opened = Geometry.find_intersect_rect(rect, raver_group.rects) &&
                     (@accepted_types - raver_group.ravers.map(&:type)).empty?
  end
end

class WindowSpawner
  # dependency on RaverGroup

  attr_reader :windows, :can_be_opened

  def initialize
    @windows = []

    @last_spawn_at = 0
    @spawn_interval = 5.seconds

    @max_types = 1
  end

  def tick
    if Kernel.tick_count % 120.seconds == 0
      @max_types += 1
    end
    if @spawn_interval < Kernel.tick_count - @last_spawn_at
      @last_spawn_at = Kernel.tick_count

      number_of_types = Numeric.rand(1..@max_types).to_i
      accepted_types = if [true, false].sample
                         number_of_types.map { || RAVER_TYPES.sample }
                       else
                         number_of_types.map { || $raver_group.ravers.map(&:type).sample }
                       end

      @windows << Window.new(x: [Numeric.rand(50..300), Numeric.rand(900..1000)].sample,
                             y: 600,
                             accepted_types: accepted_types)
    end

    @windows.each do |window|
      window.update_can_be_opened(raver_group: $raver_group)

      window.y -= 0.5
      if window.y < 0
        $score.windows_missed += 1
        @windows.delete(window)
      end
    end
  end

  # Intersected with a raver
  def close_window(window)
    $score.points += 10 ** window.types.size

    @windows.delete(window)
  end
end