require 'yaml'
MESSAGES = YAML.load_file('oo_21_msgs.yml')
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
    prompt("Nice to meet you, #{player.name}!")
    sleep(1)
    spacer(2)
    prompt(messages('welcome'))
    sleep(1)
  end

  def display_rules
    prompt(messages('rules'))
    gets
  end

  def display_wallet_funded
    clear_screen
    prompt("Wallet funded successfully.")
  end

  def display_start_game
    spacer(2)
    prompt(messages('start_first_hand'))
  end

  def display_dealing
    clear_screen
    prompt(messages('dealing'))
    sleep(2)
    clear_screen
  end

  def display_dealer_turn
    clear_screen
    prompt("Dealer's turn...")
    sleep(2)
  end

  def display_win_by_bust
    if player.busted?
      prompt("You busted, Dealer wins!")
    elsif dealer.busted?
      prompt("Dealer busted. You win!")
    end
  end

  def display_winner
    if someone_busted
      return display_win_by_bust
    end

    compare_hands
    case determine_winner
    when :player then display_player_win
    when :dealer then display_dealer_win
    when :push then display_push
    end
  end

  def display_dealer_win
    prompt("Dealer wins!")
  end

  def display_player_win
    prompt("#{player.name} wins!")
  end

  def display_push
    prompt("It's a push!")
  end

  def display_cash_out
    clear_screen
    prompt("You bought in for $#{player.buy_in_amount}")
    prompt("You cashed out $#{player.wallet}.")
  end

  def display_goodbye_message
    spacer
    prompt("Thank you for playing 21, #{player.name}!")
    spacer
    prompt("Goodbye!")
  end

  def display_exit_msg
    display_cash_out
    display_goodbye_message
  end
end

module House
  def review_rules
    spacer
    answer = ''
    loop do
      prompt(messages('ask_review_rules'))
      answer = gets.chomp
      break if respond_yes?(answer) || respond_no?(answer)
      prompt(messages('invalid_yes_no'))
    end
    clear_screen
    respond_yes?(answer) ? display_rules : prompt(messages('no_rules'))
  end

  def hit_or_stay
    spacer(3)
    choice = ''
    loop do
      prompt(messages('hit_or_stay?'))
      choice = gets.chomp.downcase.strip
      break if valid_move?(choice)
      prompt(messages('invalid_hit_stay'))
    end

    %w(h hit).include?(choice) ? :hit : :stay
  end

  def someone_busted
    player.busted? || dealer.busted?
  end

  def determine_winner
    if player.busted?
      :dealer
    elsif dealer.busted?
      :player
    elsif player.total == dealer.total
      :push
    else
      player.total > dealer.total ? :player : :dealer
    end
  end

  def settle_wager
    winner = determine_winner
    if winner == :player
      payout_win
    elsif winner == :dealer
      house_collect
    end
  end

  def positive_balance?
    player.wallet > 0
  end

  def choose_rebuy?
    choice = ''
    loop do
      prompt(messages('rebuy?'))
      choice = gets.chomp.strip
      break if respond_yes?(choice) || respond_no?(choice)
      prompt(messages('invalid_yes_no'))
    end

    respond_yes?(choice)
  end

  def rebuy
    player.set_wallet
  end

  def respond_yes?(answer)
    %w(y ye yes).include?(answer.downcase)
  end

  def respond_no?(answer)
    %w(n no).include?(answer.downcase)
  end

  private

  def valid_move?(choice)
    %w(h hit s stay).include?(choice)
  end

  def compare_hands
    spacer
    prompt("Let's compare hands!")
    sleep(1)
    spacer
    player.show_hand
    sleep(1)
    dealer.show_hand
    sleep(2)
  end

  def deduct_wager
    player.wallet -= player.current_wager
  end

  def payout_win
    payout = (player.current_wager)
    spacer(2)
    prompt("House pays #{player.name} $#{payout}!")
    player.wallet += payout
    prompt("Wallet Balance: $#{player.wallet}")
  end

  def house_collect
    deduct_wager
    spacer(2)
    prompt("You lost your $#{player.current_wager} bet to the house.")
    prompt("Wallet Balance: $#{player.wallet}")
  end
end

class Participant
  attr_accessor :name, :cards

  include Displayable

  def initialize
    set_name
    @cards = []
  end

  def hit(new_card)
    cards << new_card
  end

  def stay
    clear_screen
    prompt("#{name} chose to stay at #{total}.")
    sleep(2)
  end

  def busted?
    total > 21
  end

  def total
    total = cards.sum(&:point_value)
    aces_count = cards.count(&:ace?)
    until total <= 21 || aces_count == 0
      total -= 10
      aces_count -= 1
    end
    total
  end

  def show_hand
    puts "---- #{name}'s Hand ----"
    cards.each do |card|
      prompt(card.to_s)
    end
    prompt("Total: #{total}")
    puts ""
  end
end

class Player < Participant
  attr_accessor :wallet, :current_wager, :buy_in_amount

  def initialize
    super
    @buy_in_amount = 0
  end

  def set_name
    self.name = acquire_name
  end

  def set_wallet
    self.wallet = fund_wallet
  end

  def set_initial_buy_in
    self.buy_in_amount = wallet
  end

  def increment_buy_in_total
    self.buy_in_amount += wallet
  end

  def place_bet
    self.current_wager = acquire_bet
  end

  private

  def acquire_name
    name = nil
    loop do
      puts "What's your name?"
      name = gets.chomp.strip
      break unless name.empty?
      puts "Must enter name."
    end
    name
  end

  def fund_wallet
    fund = 0
    loop do
      prompt(messages('ask_bankroll'))
      fund = gets.chomp.to_i
      break if valid_wallet_amount?(fund)
      clear_screen
      prompt(messages('invalid_amount'))
      spacer(2)
    end
    fund
  end

  def valid_wallet_amount?(fund)
    fund > 0
  end

  def show_balance_and_ask_bet
    prompt("Current Balance: $#{wallet}")
    spacer
    prompt(messages('ask_wager'))
  end

  def acquire_bet
    wager_amount = nil
    loop do
      show_balance_and_ask_bet
      wager_amount = gets.chomp.to_i
      break if valid_bet?(wager_amount)
      clear_screen
      prompt("Please enter an amount between 1 and #{wallet}")
      spacer
    end

    wager_amount
  end

  def valid_bet?(amount)
    amount > 0 && wallet >= amount
  end
end

class Dealer < Participant
  include Displayable

  def set_name
    self.name = "Dealer"
  end

  def show_flop
    puts "---- #{name}'s Hand ----"
    prompt(cards.first.to_s)
    prompt("Unknown")
    prompt("Showing Total: #{cards.first.point_value}")
  end
end

class Card
  SUITS = %w(Hearts Diamonds Spades Clubs)
  FACES = %w(2 3 4 5 6 7 8 9 10 Jack Queen King Ace)

  attr_reader :face, :suit, :point_value

  def initialize(suit, face)
    @suit = suit
    @face = face
    @point_value = calculate_point_value(face)
  end

  def to_s
    "#{face} of #{suit}"
  end

  def ace?
    face == 'Ace'
  end

  private

  def calculate_point_value(face)
    if (2..10).include? face.to_i
      face.to_i
    elsif face == 'Ace'
      11
    else
      10
    end
  end
end

class Deck
  attr_accessor :cards

  def initialize
    @cards = []
    Card::SUITS.each do |suit|
      Card::FACES.each do |face|
        @cards << Card.new(suit, face)
      end
    end

    shuffle_cards!
  end

  def shuffle_cards!
    cards.shuffle!
  end

  def deal_one
    cards.pop
  end
end

class Game
  attr_accessor :player, :dealer, :wallet, :deck

  include Displayable
  include House

  def initialize
    clear_screen
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def start
    introduce_game
    pregame
    main_game_loop
    display_exit_msg
  end

  private

  def introduce_game
    display_welcome_message
    review_rules
  end

  def pregame
    clear_screen
    player.set_wallet
    display_wallet_funded
    player.set_initial_buy_in
    display_start_game
  end

  def main_game_loop
    loop do
      play_hand

      if !positive_balance?
        break unless choose_rebuy?
        initiate_rebuy
        next
      end

      break unless play_again?
      reset
    end
  end

  def opening_sequence
    player.place_bet
    display_dealing
    initial_deal
    player.show_hand
    dealer.show_flop
  end

  def initial_deal
    deck.shuffle_cards!
    2.times { player.cards << deck.deal_one }
    2.times { dealer.cards << deck.deal_one }
  end

  def player_move
    loop do
      move = hit_or_stay
      if move == :stay
        player.stay
        break
      elsif move == :hit
        player_hit_sequence
        break if player.busted?
      end
    end
  end

  def dealer_move
    display_dealer_turn
    dealer_move_sequence_loop
  end

  def moves_loop
    loop do
      player_move
      break if player.busted?
      dealer_move
      break
    end
  end

  def play_hand
    opening_sequence
    moves_loop
    display_winner
    settle_wager
  end

  def initiate_rebuy
    clear_screen
    rebuy
    player.increment_buy_in_total
    reset
  end

  def player_hit_sequence
    clear_screen
    prompt(messages('chose_hit'))
    sleep(2)
    player.hit(deck.deal_one)
    clear_screen
    player.show_hand
  end

  def dealer_consider_hand
    clear_screen
    dealer.show_hand
    sleep(2)
  end

  def dealer_hit_sequence
    dealer.hit(deck.deal_one)
    puts "Dealer hits..."
    sleep(2)
    clear_screen
    dealer.show_hand
  end

  def dealer_move_sequence_loop
    loop do
      dealer_consider_hand
      if dealer.total < 17
        dealer_hit_sequence
        break if dealer.busted?
      else
        dealer.stay
        break
      end
    end
  end

  def play_again?
    answer = nil
    loop do
      spacer(2)
      prompt(messages('ask_play_again?'))
      answer = gets.chomp.strip
      break if respond_yes?(answer) || respond_no?(answer)
      prompt(messages('invalid_yes_no'))
    end

    return true if respond_yes?(answer)
    false
  end

  def reset
    clear_screen
    player.cards = []
    dealer.cards = []
    player.current_wager = 0
  end
end

Game.new.start
