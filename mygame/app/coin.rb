COIN_TYPES = [:coin, :drink, :kebab, :sunglasses]

class Coin
  attr_accessor :x, :y
  include Animatable

  def prefab
    {
      x: x,
      y: y,
      w: 100,
      h: 100,
      path: "sprites/#{@type}_#{sprite_id}.png",
    }
  end

  def rect
    {
      x: x,
      y: y,
      w: 100,
      h: 100,
    }
  end

  def initialize(x:, y:)
    @x = x
    @y = y
    @animation_speed = 8
    @type = COIN_TYPES.sample
  end
end

class CoinSpawner

  attr_reader :coins

  def initialize
    @coins = []

    @last_spawn_at = 0
    @spawn_interval = 8.seconds
  end

  def tick
    if @spawn_interval < Kernel.tick_count - @last_spawn_at
      @last_spawn_at = Kernel.tick_count

      @coins << Coin.new(x: Numeric.rand(100..1000), y: 700)
    end

    $raver_group.ravers.each do |raver|
      @coins.each do |coin|
        if coin.rect.intersect_rect?(raver.rect)
          @coins.delete(coin)
        end
      end
    end

    @coins.each do |coin|
      coin.y -= 1
      if coin.y < 0
        @coins.delete(coin)
      end
    end
  end
end