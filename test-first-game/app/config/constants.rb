# Game configuration and constants
module Config
  # Screen dimensions
  SCREEN_WIDTH = 1280
  SCREEN_HEIGHT = 720

  # Perspective settings - OutRun style
  VANISHING_POINT_X = 640  # Center of screen (horizontal)
  VANISHING_POINT_Y = 680  # Horizon near top of screen (~94% screen height)
  PERSPECTIVE_STRENGTH = 0.35  # Aggressive scaling - distant objects much smaller
  WORLD_DEPTH = 1000  # Maximum depth in world coordinates
  CAMERA_Y_OFFSET = 0  # Road starts at bottom of screen (y=0)

  # Lane configuration (world coordinates)
  LANE_WIDTH = 100
  LANES = [-400, -300, -200, -100, 0, 100, 200, 300, 400]  # X positions for 9 lanes
  NUM_LANES = LANES.length

  # Player settings
  PLAYER_START_LANE = 4  # Center lane (0-indexed)
  PLAYER_START_SPEED = 8.0
  PLAYER_WIDTH = 40
  PLAYER_HEIGHT = 60
  PLAYER_Y_POSITION = 0  # Player is always at the front
  PLAYER_LANE_SWITCH_SPEED = 15  # How fast player moves between lanes
  PLAYER_COLOR = { r: 50, g: 150, b: 255 }  # Blue

  # Obstacle settings
  OBSTACLE_MIN_SPAWN_DISTANCE = 950
  OBSTACLE_MAX_SPAWN_DISTANCE = 1000
  OBSTACLE_WIDTH = 80
  OBSTACLE_HEIGHT = 100
  OBSTACLE_BASE_SPEED = 8.0
  OBSTACLE_COLORS = [
    { r: 200, g: 50, b: 50 },   # Red
    { r: 150, g: 50, b: 150 },  # Purple
    { r: 50, g: 150, b: 100 }   # Teal
  ]

  # Coin settings
  COIN_MIN_SPAWN_DISTANCE = 900
  COIN_MAX_SPAWN_DISTANCE = 1000
  COIN_SIZE = 30
  COIN_BASE_SPEED = 8.0
  COIN_SPEED_BOOST = 0.5
  COIN_SCORE_VALUE = 10
  COIN_COLOR = { r: 255, g: 215, b: 0 }  # Gold

  # Game mechanics
  GAME_OVER_THRESHOLD = 0.1
  SPEED_DECAY_ON_HIT = 2.0
  DISTANCE_MULTIPLIER = 0.1  # How fast distance accumulates

  # Road rendering
  ROAD_COLOR = { r: 40, g: 45, b: 50 }
  ROAD_EDGE_COLOR = { r: 200, g: 200, b: 200 }
  LANE_DIVIDER_COLOR = { r: 200, g: 200, b: 100 }
  LANE_DIVIDER_WIDTH = 8
  LANE_DIVIDER_SPACING = 60  # World space between divider segments
  LANE_DIVIDER_LENGTH = 40   # World space length of each segment

  # UI settings
  UI_TEXT_COLOR = { r: 255, g: 255, b: 255 }
  UI_FONT_SIZE = 4
  GAME_OVER_FONT_SIZE = 10
end

