module Animatable
  attr_accessor  :animation_speed, :sprite_count

  def sprite_id
    @animation_speed ||= 4
    @sprite_count ||= 3

    return 0 if animation_speed == 0
    (Kernel.tick_count / animation_speed).to_i % sprite_count
  end
end
