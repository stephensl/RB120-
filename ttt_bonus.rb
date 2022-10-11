require 'pry'
require 'yaml'
MESSAGES = YAML.load_file("ttt_bonus_msgs.yml")

module Displayable
  def messages(communication)
    MESSAGES[communication]
  end

  def prompt(string)
    puts "=> #{string}"
  end

  def display_welcome_message
    prompt(messages("welcome") + "#{human.name}!")
    spacer
    sleep(1)
  end

  def display_opponent_choice
    clear_screen
    prompt("You chose to play against: #{computer.name}!")
    spacer(1)
    prompt("#{computer.name}'s marker: #{computer.marker}")
    spacer(2)
  end

  def joinor(arr, delimiter = ", ", last_word = 'or')
    case arr.size
    when 0 then ''
    when 1 then arr.first
    when 2 then arr.join(" #{last_word} ")
    else
      arr[-1] = "#{last_word} #{arr.last}"
      arr.join(delimiter)
    end
  end

  def clear_screen
    system 'clear'
  end

  def spacer(lines = 1)
    puts("\n" * lines)
  end

  def display_marker_choice
    clear_screen
    prompt "You chose '#{human.marker}' as your marker."
    puts ''
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def display_board
    puts "Your marker: #{human.marker}. Computer marker: #{computer.marker}"
    spacer
    board.draw
    spacer
  end

  def display_scoreboard
    puts messages('scoreboard')
    prompt("#{human.name}: #{human.score}")
    prompt("#{computer.name}: #{computer.score}")
    spacer
    prompt("First to #{max_wins} is the champion!")
  end

  def clear_screen_and_display_board
    clear_screen
    display_board
  end

  def display_rules
    clear_screen
    puts "The Rules".center(80)
    puts messages('display_rules')
    gets
    clear_screen
  end

  def review_rules
    answer = ''
    loop do
      puts messages('review_rules')
      answer = gets.chomp
      break if respond_yes?(answer) || respond_no?(answer)
      prompt(messages('invalid_yes_no'))
    end
    clear_screen
    respond_yes?(answer) ? display_rules : prompt(messages('no_rules'))
  end

  def display_champion
    sleep(2)
    clear_screen
    if human.score == max_wins
      puts messages('congrats')
    else
      prompt("#{computer.name} is the Champion. Better luck next time!")
    end
    sleep(2)
  end

  private

  def respond_yes?(answer)
    %w(y ye yes).include?(answer.downcase)
  end

  def respond_no?(answer)
    %w(n no).include?(answer.downcase)
  end
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]

  def initialize
    @squares = {}
    reset
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def [](key)
    @squares[key]
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  def find_winnable_lines
    winnable_lines = []
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      winnable_lines << line if two_in_a_row?(squares)
    end
    winnable_lines
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end

  def two_in_a_row?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != 2
    markers.min == markers.max
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end

class Player
  attr_accessor :marker, :name, :score

  include Displayable

  def initialize
    set_name
    @score = 0
  end
end

class Human < Player
  def set_name
    self.name = acquire_name
  end

  def assign_marker(computer_marker)
    self.marker = acquire_marker(computer_marker)
  end

  private

  def acquire_name
    clear_screen
    name = ''
    loop do
      prompt(messages('ask_name'))
      name = gets.chomp
      break unless name.empty?
      prompt(messages('invalid_name'))
      puts ''
    end
    name
  end

  def acquire_marker(computer_marker)
    marker = nil
    prompt(messages('ask_marker'))
    loop do
      marker = gets.chomp.strip
      break unless invalid_marker?(marker, computer_marker)
      clear_screen
      prompt("Marker Choice: #{marker}. Opponent's marker: #{computer_marker}.")
      prompt(messages('invalid_marker'))
    end
    marker
  end

  def invalid_marker?(marker, other_marker)
    marker.length > 1 || marker.empty? || marker == other_marker
  end
end

class Computer < Player
  OPPONENT_AND_LEVEL = { 'R2D2' => 'easy',
                         'C3P0' => 'medium',
                         'Terminator' => 'hard' }

  attr_accessor :level

  def initialize
    super
    assign_marker
    set_level
  end

  def set_name
    self.name = assign_identity
  end

  def assign_marker
    self.marker = name.chars.first
  end

  def set_level
    self.level = OPPONENT_AND_LEVEL[name]
  end

  private

  def choose_opponent
    clear_screen
    opponent = ''
    loop do
      prompt(messages('choose_opponent'))
      opponent = gets.chomp.to_i
      break if [1, 2, 3].include?(opponent)
      prompt(messages("invalid_opponent"))
    end
    opponent
  end

  def assign_identity
    opponent = choose_opponent
    case opponent
    when 1 then "R2D2"
    when 2 then "C3P0"
    when 3 then "Terminator"
    end
  end
end

class TTTGame
  attr_accessor :board, :human, :computer, :max_wins

  include Displayable

  def initialize
    @board = Board.new
    @human = Human.new
    @max_wins = 5
  end

  def introduce_game
    clear_screen
    display_welcome_message
    review_rules
  end

  def pregame
    create_opponent
    display_opponent_choice
    human.assign_marker(computer.marker)
    set_max_wins
    @current_marker = first_to_move
    clear_screen
  end

  def main_game_loop
    loop do
      display_board
      player_move
      display_result
      increment_score
      max_wins_reached? ? break : display_scoreboard
      gets
      reset_board
    end
  end

  def play
    introduce_game
    loop do
      pregame
      main_game_loop
      display_champion
      break unless play_again?
      display_play_again_message
      full_reset
    end
    display_goodbye_message
  end

  def reset_board
    board.reset
  end

  def reset_score
    human.score = 0
    computer.score = 0
  end

  def full_reset
    reset_board
    reset_score
  end

  def create_opponent
    @computer = Computer.new
  end

  def set_max_wins
    clear_screen
    custom_max = acquire_custom_max
    self.max_wins = custom_max.to_i unless custom_max.empty?
  end

  def acquire_custom_max
    answer = ''
    prompt(messages("default_max"))
    prompt("Target number of wins currently set to #{max_wins}.")
    loop do
      prompt(messages('custom_max?'))
      answer = gets.chomp
      break if answer.empty? || (1..10).include?(answer.to_i)
      prompt(messages("invalid_max"))
    end
    answer
  end

  def first_to_move
    clear_screen
    choice = nil

    loop do
      prompt(messages("who_goes_first?"))
      choice = gets.chomp.downcase.strip
      break if %w(1 2 3).include?(choice)
      prompt(messages("invalid_goes_first"))
    end

    choice == '1' ? human.marker : computer.marker
  end

  def max_wins_reached?
    human.score == max_wins || computer.score == max_wins
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won!"
    when computer.marker
      puts "Computer won!"
    else
      puts "It's a tie!"
    end
  end

  private

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = computer.marker
    else
      computer_moves
      @current_marker = human.marker
    end
  end

  def human_turn?
    @current_marker == human.marker
  end

  def human_moves
    puts "Choose a square (#{joinor(board.unmarked_keys)}):"
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry that's not a valid choice."
    end
    board[square] = human.marker
  end

  def computer_moves
    square = case computer.level
             when 'easy' then computer_easy_move
             when 'medium' then computer_medium_move
             when 'hard' then computer_hard_move
             end

    board[square] = computer.marker
  end

  def computer_easy_move
    board.unmarked_keys.sample
  end

  def computer_medium_move
    if computer_defense_needed?
      computer_defense_move
    else
      computer_easy_move
    end
  end

  def computer_hard_move
    if computer_offense_available?
      computer_offense_move
    elsif computer_defense_needed?
      computer_defense_move
    else
      computer_easy_move
    end
  end

  def computer_offense_available?
    winnable_lines = board.find_winnable_lines
    return false if winnable_lines.empty?
    winnable_lines.each do |line|
      if line.any? { |square| board[square].marker == computer.marker }
        return true
      end
    end
    false
  end

  def computer_offense_move
    winnable_lines = board.find_winnable_lines
    winnable_lines.each do |line|
      if line.any? { |square| board[square].marker == computer.marker }
        line.each { |square| return square if board[square].unmarked? }
      end
    end
  end

  def computer_defense_needed?
    defensive_lines = board.find_winnable_lines
    !defensive_lines.empty?
  end

  def computer_defense_move
    defensive_lines = board.find_winnable_lines
    defensive_lines.each do |line|
      if line.any? { |square| board[square].marker == human.marker }
        line.each { |square| return square if board[square].unmarked? }
      end
    end
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board
    end
  end

  def increment_score
    if board.winning_marker == human.marker
      human.score += 1
    elsif board.winning_marker == computer.marker
      computer.score += 1
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again?"
      answer = gets.chomp.downcase
      break if %w(y n).include?(answer)
      puts "Sorry, must enter y or n"
    end

    answer == 'y'
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end
end

game = TTTGame.new
game.play
