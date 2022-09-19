require 'yaml'
MESSAGES = YAML.load_file("rps_messages.yml")

module Displayable
  def messages(communication)
    MESSAGES[communication]
  end

  def prompt(string)
    puts "=> #{string}"
  end

  def clear_screen
    system 'clear'
  end

  def spacer(lines = 1)
    puts("\n" * lines)
  end

  def display_welcome_message
    clear_screen
    prompt("Nice to meet you, #{human.name}!")
    sleep(1)
    spacer
    prompt(messages('welcome'))
    sleep(1.5)
  end

  def display_goodbye_message
    prompt(messages('goodbye'))
  end

  def display_rules
    clear_screen
    prompt(messages('display_rules'))
    gets
    clear_screen
  end

  def display_opponent_choice
    clear_screen
    prompt("You chose to play against #{computer.name}!")
    spacer(2)
  end

  def display_moves
    clear_screen
    prompt("You chose #{human.move}.")
    spacer
    puts "=> #{computer.name} chose #{computer.move}."
  end

  def display_battle
    pause_for_battle
    action = Moves::ACTION_WORDS[human.move.name][computer.move.name]
    spacer(2)
    prompt("Result: #{human.move} #{action} #{computer.move}!")
  end

  def display_winner
    spacer(2)
    if determine_winner == human
      prompt("#{human.name} won!")
    elsif determine_winner == computer
      prompt("#{computer.name} won!")
    else
      prompt("It's a tie!")
    end
    spacer(2)
  end

  def display_game_history
    puts messages('game_review')
    human.history.each_with_index do |move, idx|
      puts "Round #{idx + 1}:
        #{human.name} chose: #{move}
        #{computer.name} chose: #{computer.history[idx]}
        Win?: #{move.victorious?(computer.history[idx])} "
    end
  end

  def display_scoreboard
    puts messages('scoreboard')
    prompt("#{human.name}: #{human.score}")
    prompt("#{computer.name}: #{computer.score}")
    prompt("First to #{max_wins} wins is crowned Champion!")
    spacer(2)
    puts "Press 'enter' to continue"
    gets
    clear_screen
  end

  def display_final_score
    spacer
    puts "Final Score"
    puts "-----------"
    prompt("#{human.name}: #{human.score}")
    prompt("#{computer.name}: #{computer.score}")
    sleep(1.5)
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

  def pause_for_battle
    spacer
    sleep(1)
    prompt(messages('epic_battle'))
    sleep(1.5)
  end
end

module Moves
  VALID_MOVES = { '1' => 'rock',
                  '2' => 'paper',
                  '3' => 'scissors',
                  '4' => 'lizard',
                  '5' => 'spock' }

  ACTION_WORDS = { 'rock' => { 'paper' => 'is covered by',
                               'scissors' => 'crushes',
                               'lizard' => 'smashes',
                               'spock' => 'is vaporized by',
                               'rock' => "talks geology with" },
                   'paper' => { 'rock' => 'covers',
                                'scissors' => 'is cut by',
                                'lizard' => 'is eaten by',
                                'spock' => 'disproves',
                                'paper' => 'reads with' },
                   'scissors' => { 'rock' => 'are crushed by',
                                   'paper' => 'cuts',
                                   'lizard' => 'decapitates',
                                   'spock' => 'are smashed by',
                                   'scissors' => 'collages with' },
                   'lizard' => { 'rock' => 'is smashed by',
                                 'paper' => 'eats',
                                 'scissors' => 'is decapitated by',
                                 'spock' => 'poisons',
                                 'lizard' => 'eats flies with' },
                   'spock' => { 'rock' => 'vaporizes',
                                'paper' => 'is disproved by',
                                'scissors' => 'smashes',
                                'lizard' => 'is poisoned by',
                                'spock' => 'meets his twin brother' } }

  def victorious?(other_move)
    self.beats.include?(other_move)
  end

  def to_s
    self.name 
  end
  
  class AllMoves
    attr_reader :name, :beats 
    
    include Moves 
    
    def initialize(name, beats)
      @name = name 
      @beats = beats
    end 
  end 

  class Rock < AllMoves
    def initialize
      super('rock', ['scissors', 'lizard'])
    end
  end

  class Paper < AllMoves
    def initialize
      super('paper', ['rock', 'spock'])
    end
  end

  class Scissors < AllMoves
    def initialize
      super('scissors', ['paper', 'lizard'])
    end
  end

  class Lizard < AllMoves
    def initialize
      super('lizard', ['paper', 'spock'])
    end
  end

  class Spock < AllMoves
    def initialize
      super('spock', ['rock', 'scissors'])
    end
  end
end

class Player
  attr_accessor :move, :name, :score, :history

  include Displayable

  def initialize
    set_name
    @score = 0
    @history = []
  end

  def add_to_history(move)
    @history << move
  end
end

class Human < Player
  include Moves

  def set_name
    self.name = acquire_name
  end

  def set_move
    choice = acquire_move
    self.move = create_move(choice)
    add_to_history(move)
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
    end
    name
  end

  def acquire_move
    clear_screen
    choice = nil
    loop do
      prompt(messages('move_options'))
      choice = gets.chomp
      break if VALID_MOVES.keys.include?(choice)
      prompt(messages("invalid_move_choice"))
      spacer(2)
    end
    choice
  end

  def create_move(choice)
    case choice
    when '1' then Moves::Rock.new
    when '2' then Moves::Paper.new
    when '3' then Moves::Scissors.new
    when '4' then Moves::Lizard.new
    when '5' then Moves::Spock.new
    end
  end
end

class Computer < Player
  include Moves

  PERSONALITIES = { 'R2D2' => [Rock.new],
                    'C3P0' => [Spock.new, Paper.new, Scissors.new],
                    'Terminator' => [Lizard.new, Rock.new, Scissors.new] }

  def set_name
    self.name = assign_identity
  end

  def set_move
    self.move = PERSONALITIES[name].sample
    add_to_history(move.name)
  end

  private

  def choose_opponent
    opponent = ''
    loop do
      prompt(messages('choose_opponent'))
      opponent = gets.chomp.to_i
      break if [1, 2, 3].include?(opponent)
      spacer
      prompt(messages("invalid_opponent"))
      spacer(2)
    end
    opponent
  end

  def assign_identity
    opponent = choose_opponent
    case opponent
    when 1 then 'R2D2'
    when 2 then 'C3P0'
    when 3 then 'Terminator'
    end
  end
end

module Referee
  include Displayable

  def set_max_wins
    custom_max = acquire_custom_max
    self.max_wins = custom_max.to_i unless custom_max.empty?
  end

  def increment_score
    if determine_winner == human
      human.score += 1
    elsif determine_winner == computer
      computer.score += 1
    end
  end

  def reset_scores
    human.score = 0
    computer.score = 0
  end

  def max_wins_reached?
    human.score == max_wins || computer.score == max_wins
  end

  def review_rules
    spacer
    answer = ''
    loop do
      prompt(messages('review_rules'))
      answer = gets.chomp
      break if respond_yes?(answer) || respond_no?(answer)
      prompt(messages('invalid_yes_no'))
    end
    clear_screen
    respond_yes?(answer) ? display_rules : prompt(messages('no_rules'))
  end

  def review_champion
    display_champion
    display_final_score
    display_game_history
  end

  private

  def respond_yes?(answer)
    %w(y ye yes).include?(answer.downcase)
  end

  def respond_no?(answer)
    %w(n no).include?(answer.downcase)
  end

  def acquire_custom_max
    answer = ''
    prompt(messages("default_max"))
    prompt("Target number of wins currently set to #{max_wins}.")
    loop do
      prompt(messages('custom_max?'))
      answer = gets.chomp
      break if answer.empty? || (1..25).include?(answer.to_i)
      prompt(messages("invalid_max"))
    end
    answer
  end

  def determine_winner
    if human.move.victorious?(computer.move.name)
      human
    elsif computer.move.victorious?(human.move.name)
      computer
    end
  end
end

# Orchestration Engine
class RPSGame
  attr_accessor :human, :computer, :max_wins

  include Displayable
  include Referee

  def initialize
    @human = Human.new
    @max_wins = 5
  end

  def create_opponent
    @computer = Computer.new
  end

  def introduce_game
    display_welcome_message
    review_rules
  end

  def pregame
    create_opponent
    display_opponent_choice
    set_max_wins
  end

  def gameplay_loop
    loop do
      human.set_move
      computer.set_move
      display_moves
      display_battle
      determine_winner
      display_winner
      increment_score
      max_wins_reached? ? break : display_scoreboard
    end
  end

  def play_again?
    answer = nil
    loop do
      spacer(2)
      prompt(messages('ask_play_again?'))
      answer = gets.chomp
      break if respond_yes?(answer) || respond_no?(answer)
      prompt(messages('invalid_yes_no'))
    end

    return true if respond_yes?(answer)
    false
  end

  def play
    introduce_game
    loop do
      pregame
      gameplay_loop
      review_champion
      break unless play_again?
      reset_scores
      clear_screen
    end
    display_goodbye_message
  end
end

RPSGame.new.play