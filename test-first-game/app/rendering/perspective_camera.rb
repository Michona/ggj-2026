# Perspective camera for isometric/pseudo-3D rendering
class PerspectiveCamera
  def initialize
    @vanishing_point_x = Config::VANISHING_POINT_X
    @vanishing_point_y = Config::VANISHING_POINT_Y
    @perspective_strength = Config::PERSPECTIVE_STRENGTH
    @world_depth = Config::WORLD_DEPTH
    @camera_y_offset = Config::CAMERA_Y_OFFSET
  end

  # Calculate perspective scale based on depth (y position in world)
  # Objects further away (higher y) appear smaller
  def perspective_scale(world_y)
    # Normalize world_y to 0-1 range
    depth_ratio = world_y / @world_depth
    depth_ratio = [[depth_ratio, 0].max, 1].min  # Clamp to 0-1

    # Scale from 1.0 (close) to perspective_strength (far)
    min_scale = @perspective_strength
    scale = 1.0 - (depth_ratio * (1.0 - min_scale))

    return scale
  end

  # Convert world coordinates to isometric screen coordinates
  def world_to_screen(world_x, world_y)
    scale = perspective_scale(world_y)

    # Calculate screen position with perspective
    # X: interpolate between world position and vanishing point based on depth
    depth_ratio = world_y / @world_depth
    depth_ratio = [[depth_ratio, 0].max, 1].min

    screen_x = @vanishing_point_x + (world_x * scale)

    # Y: map world depth to screen height
    # Near objects (y=0) appear at bottom, far objects (y=world_depth) appear at vanishing point
    screen_y = @camera_y_offset + (depth_ratio * (@vanishing_point_y - @camera_y_offset))

    return { x: screen_x, y: screen_y, scale: scale }
  end

  # Convert world rectangle to screen rectangle with perspective
  # Scales both width and height uniformly to maintain aspect ratio
  def world_rect_to_screen(world_x, world_y, world_w, world_h)
    # Get screen position and scale at the object's depth
    screen_pos = world_to_screen(world_x, world_y)

    # Scale both width and height uniformly by perspective
    scaled_w = world_w * screen_pos[:scale]
    scaled_h = world_h * screen_pos[:scale]

    # Center the object horizontally on its position
    screen_x = screen_pos[:x] - (scaled_w / 2)

    # Y position - center vertically or use base position
    screen_y = screen_pos[:y]

    return {
      x: screen_x,
      y: screen_y,
      w: scaled_w,
      h: scaled_h,
      scale: screen_pos[:scale]
    }
  end

  attr_reader :vanishing_point_x, :vanishing_point_y, :world_depth, :camera_y_offset
end

