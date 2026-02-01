class Rave
  include Animatable

  attr_accessor :delta_sync_time, :elapsed_time

  def prefab
    @elapsed_time += 1
    progress_in_sec = (elapsed_time + delta_sync_time) % 21.343741.seconds

    if progress_in_sec >= 4.seconds && progress_in_sec <= 5.seconds
       @animation_speed = 2
    elsif progress_in_sec >= 9.seconds + 30 && progress_in_sec <= 10.seconds + 30
      @animation_speed = 16
    elsif progress_in_sec >= 14.seconds + 30 && progress_in_sec <= 15.seconds + 30
      @animation_speed = 2
    elsif progress_in_sec >= 19.seconds
      @animation_speed = 4
    else
      @animation_speed = 8
    end
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

  def initialize()
    @sprite_count = 4
    @animation_speed = 8
    @delta_sync_time = 0
    @elapsed_time = 0
  end
end