class Rave
  include Animatable
  def prefab
    {
      x: 1280 / 2 + 30,
      y: 720 / 2 + 30,
      w: 1280 * 1.1,
      h: 820 * 1.08474745 * 1.1,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: "sprites/rave_#{sprite_id}.png",
    }
  end

  def initialize
    @sprite_count =4
    @animation_speed = 8
  end

end