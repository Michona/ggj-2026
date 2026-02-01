class Background
  attr_accessor :x, :y

  def prefab
    {
      x: x,
      y: y,
      w: 1280,
      h: 720,
      path: "sprites/bg_1.png",
    }
  end

  def initialize(x:, y:)
    @x = x
    @y = y
  end
end

class BackgroundSpawner

  attr_reader :backgrounds

  def initialize
    @backgrounds = [Background.new(x: 0, y: 0), Background.new(x: 0, y: 720)]
  end

  def tick
    @backgrounds.each do |background|
      background.y -= 1

      if background.y < -720
        @backgrounds.delete(background)
        @backgrounds << Background.new(x: 0, y: background.y + 2 * 720)
      end
    end
  end
end