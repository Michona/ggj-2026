
SCREEN_HEIGHT = 720
SCREEN_WIDTH = 1280

MID_HEIGHT = SCREEN_HEIGHT / 2
MID_WIDTH = SCREEN_WIDTH / 2

def mk_music(args)
  if args.state.tick_count == 1
    # music = "sounds/gamejam-dnb.wav"
    music = "sounds/LOFI-GAMEJAM-1.wav"
    args.audio[:music] = { input: music, looping: true, gain: 0.0}
    args.state.music_muted ||= true
  end

  if args.inputs.mouse.click
    if args.state.music_muted
      args.audio[:music].gain = 1.0
      args.state.music_muted = false
    else
      args.audio[:music].gain = 0.0
      args.state.music_muted = true
    end
  end
end

def mk_road(args)
  road_bottom = 0
  road_height = (SCREEN_HEIGHT * 0.7).to_i
  road_width_bottom = (SCREEN_WIDTH * 0.96).to_i
  road_perspective = 0.07

  road_width_top = (road_width_bottom * road_perspective).to_i
  offset_bottom = ((road_width_bottom) / 2)
  offset_top = ((road_width_top) / 2)

  args.outputs.lines << {x: MID_WIDTH - offset_bottom, y: road_bottom, x2: MID_WIDTH - offset_top, y2: road_height}
  args.outputs.lines << {x: MID_WIDTH + offset_bottom, y: road_bottom, x2: MID_WIDTH + offset_top, y2: road_height}
  args.outputs.lines << {x: 0, y: road_height, x2: SCREEN_WIDTH, y2: road_height}
end

def round_towards_sign(n)
  if n > 0
    n.ceil
  else
    n.floor
  end
end

# AKA the jiggle!
class Spring
  attr_accessor :m, :dt, :dt2, :cs_upper, :cs_lower, :cd_upper, :cd_lower, :s_max, :c_max

  def initialize(cs_upper, cs_lower, cd_upper, cd_lower)
    @cs_upper = cs_upper # stable stiffness coefficient 0 <= Cs <= 1
    @cs_lower = cs_lower
    @cd_upper = cd_upper # stable damping coefficient 0 <= Cd <= 1
    @cd_lower = cd_lower

    @dt = 1.0 / 60.0 # delta time
    @dt2 = @dt ** 2
    @s_max = 1.0 / @dt2 # stiffness coefficient
    @c_max = 1.0 / @dt # damping coefficient
  end

  def spring(d0, d1, v1, i)
    dx = (d1 - d0).to_f

    cs = @cs_lower + ((@cs_upper - @cs_lower) / (1.0 + i))
    cd = @cd_lower + ((@cd_upper - @cd_lower) / (1.0 + i))

    f = -(cs * @s_max * dx) - (cd *  @c_max * v1)
    a = f

    v = v1 + a * @dt
    d = d1 + v * @dt

    {
      d: d,
      v: v
    }
  end
end

class Player
  attr_accessor :players
  def initialize(x, y, cnt, sprite_size)
    @sprite_size = sprite_size
    @players =
      cnt.times.map do |i|
        { x: x,
          y: y + i * @sprite_size,
          xv: 0.0,
          yv: 0.0,
          color: i == 3 ? "red" : "blue" }
      end

    # @spring_x = Spring.new(0.47, 0.67)
    # @spring_x = Spring.new(0.3, 0.4)
    @spring_x = Spring.new(0.3, 0.4)
    @spring_y = Spring.new(0.35, 0.55)
  end

  def set_x x
    @players[0].x = x
  end

  def move_x x
    @players[0].x += x
  end

  def set_y y
    @players[0].y = y
  end

  def move_y y
    @players[0].y += y
  end

  def delete_at i
    p = @players[i]
    @players.delete_at(i)
    p
  end

  def switch_root i
    p = @players[i]
    @players[i] = @players[0]
    @players[0] = p
  end

  def tick
    @players.each_cons(2).with_index do |(p0, p1), i|
      sx = @spring_x.spring(p0.x , p1.x, p1.xv, i.to_f)
      p1.x = sx.d
      p1.xv = sx.v

      sy = @spring_y.spring(p0.y + @sprite_size, p1.y, p1.yv, 0.99)
      p1.y = sy.d
      p1.yv = sy.v
    end
  end

end

# add curl
# add pickup
#

def laurence_tick(args)
  args.outputs.labels << {x: 0, y: 0, anchor_x: 0, anchor_y: 0, r: 255, a: 128, text: "frame: #{Kernel.tick_count}", font: '../samples/01_rendering_basics/01_labels/manaspc.ttf', size_enum: 5}
  mk_music args
  mk_road args

  sprite_size = 50

  args.state.player ||= Player.new(SCREEN_WIDTH / 2, 50, 10, sprite_size)
  # args.state.players = args.state.player.players

  velocity_y = 20
  velocity_x = 20

  if args.inputs.up
    args.state.player.move_y(velocity_y)
  end
  if args.inputs.down
    args.state.player.move_y(-velocity_y)
  end

  if args.inputs.right
    args.state.player.move_x(velocity_x)
  end

  if args.inputs.left
    args.state.player.move_x(-velocity_x)
  end

  if args.inputs.keyboard.key_down.k
    args.state.player.switch_root 3
  end

  if args.inputs.keyboard.key_down.j
    args.state.player.delete_at(3)
  end

  if args.inputs.keyboard.key_down.l
    args.state.player.delete_at(0)
  end


  args.state.player.tick


  args.state.player.players.each_with_index do |p, i|
    args.outputs.sprites << {x: p.x, y: p.y, w: sprite_size, h: sprite_size, anchor_x: 0.5, anchor_y: 0.5, path: "sprites/misc/lowrez-ship-#{p.color}.png"}
    args.outputs.borders << {x: p.x, y: p.y, w: sprite_size, h: sprite_size, anchor_x: 0.5, anchor_y: 0.5}
  end
end