class Window
  attr_accessor :x, :y, :h, :w, :can_be_opened

  def prefab
    {
      x: x,
      y: y,
      w: if can_be_opened
           w * 1.1
         else
           w
         end,
      h: if can_be_opened
           h * 1.1
         else
           h
         end,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: "sprites/window_#{@sprite_id}.png",
    }
  end

  # def h
  #   if can_be_opened
  #     110
  #   else
  #     100
  #   end
  # end
  #
  # def w
  #   if can_be_opened
  #     220
  #   else
  #     200
  #   end
  # end

  def types
    @accepted_types
  end

  def indicator_prefabs
    indicator_size = 70
    @accepted_types.each_with_index.map do |type, index|
      delta = if x < 500
                -indicator_size * 0.6 * index - (w / 2)
              else
                w * 1/2 + -indicator_size + indicator_size * 0.6 * index
              end

      {
        x: x + delta,
        y: y - h / 2,
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
      anchor_x: 0.5,
      anchor_y: 0.5,
    }
  end

  def initialize(x:, y:, accepted_types:)
    @x = x
    @y = y
    @accepted_types = accepted_types
    @can_be_opened = false
    @sprite_id = Numeric.rand(0..4)
    @w = 200
    @h = 100
  end

  def update_can_be_opened(raver_group:)
    return false if raver_group.ravers.size == 1
    @can_be_opened = Geometry.find_intersect_rect(rect, raver_group.rects) &&
                     (@accepted_types - raver_group.ravers.map(&:type)).empty?
  end
end

class WindowSpawner
  # dependency on RaverGroup

  attr_reader :windows, :dying_windows, :can_be_opened

  def initialize
    @windows = []
    @dying_windows = []

    @last_spawn_at = 0
    @spawn_interval = 5.seconds

    @max_types = 1
  end

  def tick
    if Kernel.tick_count % 40.seconds == 0
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

      @windows << Window.new(x: [Numeric.rand(100..300), Numeric.rand(800..900)].sample,
                             y: 600,
                             accepted_types: accepted_types)
    end

    @windows.each do |window|
      window.update_can_be_opened(raver_group: $raver_group)

      window.y -= 0.5
      if window.y < 0
        $score.windows_missed += 1
        delete_window(window)
      end
    end

    @dying_windows.each do |window|
      window.h *= 0.9
      window.w *= 0.9

      if window.h < 40
        @dying_windows.delete(window)
      end
    end
  end

  # Intersected with a raver
  def close_window(window)
    $score.points += 10 ** window.types.size
    delete_window(window)
  end

  def delete_window(window)
    @dying_windows << window
    @windows.delete(window)
  end
end