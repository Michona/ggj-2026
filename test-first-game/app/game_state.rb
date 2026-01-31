# Game state management
class GameState
  attr_accessor :player, :obstacles, :coins, :score, :distance, :game_over, :road_offset

  def initialize
    @player = Player.new
    @obstacles = []
    @coins = []
    @score = 0
    @distance = 0
    @road_offset = 0  # Tracks road animation at same speed as objects
    @game_over = false
  end

  def update
    # Update distance based on player speed (for score display)
    @distance += @player.speed * Config::DISTANCE_MULTIPLIER

    # Update road offset at constant world-space speed (same as objects)
    # Both road markings and objects move at constant speed in world space
    # The perspective projection makes them appear to accelerate on screen
    @road_offset += @player.speed

    # Update player
    @player.update

    # Update obstacles
    @obstacles.each { |obs| obs.update(@player.speed) }
    @obstacles.reject! { |obs| obs.off_screen? }

    # Update coins
    @coins.each { |coin| coin.update(@player.speed) }
    @coins.reject! { |coin| coin.off_screen? }

    # Check game over condition
    if @player.game_over?
      @game_over = true
    end
  end

  def reset
    @player.reset
    @obstacles.clear
    @coins.clear
    @score = 0
    @distance = 0
    @road_offset = 0
    @game_over = false
  end
end

