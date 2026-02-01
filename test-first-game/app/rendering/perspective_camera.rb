# Perspective camera for isometric/pseudo-3D rendering
class PerspectiveCamera
  def initialize
    @vanishing_point_x = Config::VANISHING_POINT_X
    @vanishing_point_y = Config::VANISHING_POINT_Y
    @perspective_strength = Config::PERSPECTIVE_STRENGTH
    @world_depth = Config::WORLD_DEPTH
    @camera_y_offset = Config::CAMERA_Y_OFFSET
    @shake_timer = 0
    @shake_offset_x = 0
    @shake_offset_y = 0
  end

  def trigger_shake(intensity = 5)
    # Trigger camera shake with given intensity (duration in frames)
    @shake_timer = intensity * 6  # 6 frames per intensity level
  end

  def update
    # Update shake effect
    if @shake_timer > 0
      # Generate random shake offset
      shake_magnitude = (@shake_timer / 6.0).ceil  # Decreases as timer counts down
      @shake_offset_x = (rand * shake_magnitude * 2) - shake_magnitude
      @shake_offset_y = (rand * shake_magnitude * 2) - shake_magnitude
      @shake_timer -= 1
    else
      @shake_offset_x = 0
      @shake_offset_y = 0
    end
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

    # Apply shake offset to vanishing point
    vp_x = @vanishing_point_x + @shake_offset_x
    vp_y = @vanishing_point_y + @shake_offset_y

    screen_x = vp_x + (world_x * scale)

    # Y: map world depth to screen height
    # Near objects (y=0) appear at bottom, far objects (y=world_depth) appear at vanishing point
    screen_y = @camera_y_offset + (depth_ratio * (vp_y - @camera_y_offset))

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

