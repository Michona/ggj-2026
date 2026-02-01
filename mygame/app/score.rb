class Score
  attr_accessor :points, :windows_missed, :highest_stack, :max_windows

  def initialize
    @points = 0
    @windows_missed = 0
    @highest_stack = 0
    @max_windows = 5
  end

  def has_died?
    @windows_missed >= @max_windows
  end
end