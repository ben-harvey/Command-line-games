require 'io/console'

module Hand
  def show_hand
    puts "#{name} has: "
    hand.each do |card|
      puts card
    end
  end

  def hit
    deck.deal(self)
  end

  def busted?
    hand_total > Game::WIN_THRESHOLD
  end

  def hand_values
    hand.map(&:value)
  end

  def hand_total
    hand_values.inject(&:+)
  end

  def ace_value!
    aces = hand.select { |card| card.rank == "Ace" }
    aces.each do |ace|
      break if hand_total <= Game::WIN_THRESHOLD
      ace.value = 1
    end
  end

  def join_cards(hand)
    cards = hand.map(&:to_s)
    end_string = 'and '
    case hand.size
    when 2
      cards.join(' ' + end_string)
    else
      cards[-1].insert(0, end_string)
      cards.join(', ')
    end
  end
end

class Participant
  include Hand

  attr_accessor :hand, :name, :score
  def initialize(name)
    @name = name
    @hand = []
    @score = 0
  end
end

class Player < Participant; end

class Dealer < Participant; end

class Card
  FACE_CARDS = %w[Jack Queen King].freeze
  TAKE_AN = ['8', 'Ace']

  attr_reader :rank, :suit
  attr_accessor :value

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
    @value = card_value
  end

  def to_s
    "#{indefinite_article} #{rank} of #{suit}"
  end

  def indefinite_article
    TAKE_AN.include?(rank) ? 'an' : 'a'
  end

  def card_value
    if (2..10).cover?(rank)
      rank
    elsif FACE_CARDS.include?(rank)
      10
    elsif rank == "Ace"
      11
    end
  end
end

class Deck
  FACE_CARDS = %w[Jack Queen King].freeze
  RANKS = (2..10).to_a + FACE_CARDS + ["Ace"]
  SUITS = %w[Hearts Clubs Diamonds Spades].freeze

  attr_accessor :cards

  def initialize
    @cards = []
    initialize_deck
  end

  def deal(recipient)
    recipient.hand << cards.pop
  end

  private

  def initialize_deck
    SUITS.each do |suit|
      RANKS.each do |rank|
        cards << Card.new(rank, suit)
      end
    end
    cards.shuffle!
  end
end

class Game
  FACE_VALUES = 10
  ACE_VALUES = [1, 11]
  WIN_THRESHOLD = 21
  STAY_THRESHOLD = 17
  ROUNDS = 3
  DECORATION = "=-=-=-=-=-=-=-=-=-=-=-="

  attr_reader :player, :dealer, :deck
  def initialize
    @deck = Deck.new
    @player = Player.new("Ed")
    @dealer = Dealer.new("Dealer")
  end

  # rubocop:disable Metrics/MethodLength
  # at [16/15], don't want to over-refactor here

  def start # gameplay orchestration engine
    display_welcome
    loop do
      reset_game
      loop do
        reset_hands
        set_up_game
        player_turn
        dealer_turn unless player.busted?
        increment_score
        display_result
        break if find_champion
      end
      display_champion
      break unless play_again?
    end
    display_goodbye
  end
  # rubocop:enable Metrics/MethodLength

  private

  def set_up_game
    clear_screen()
    display_rounds_won()
    deal_initial_hand
    display_initial_dealer_hand
    display_hand(player)
  end

  def display_goodbye
    prompt "Thanks for playing 21, goodbye!"
  end

  def reset_game
    clear_screen
    player.score = 0
    dealer.score = 0
    reset_hands
  end

  def reset_hands
    player.hand = []
    dealer.hand = []
  end

  def play_again?
    loop do
      prompt "Would you like to play another round? ('y' or 'n')"
      response = gets.chomp.downcase
      case response
      when 'y'
        return true
      when 'n'
        return false
      else
        prompt "Please enter 'y' or 'n'."
      end
    end
  end

  def prompt(message)
    puts "=> #{message}"
  end

  def find_champion # returns player, dealer, or nil
    return player if player.score == ROUNDS
    return dealer if dealer.score == ROUNDS
    nil
  end

  def display_champion
    puts ''
    puts DECORATION
    puts ''
    prompt "#{find_champion.name} is the champion of this round!"
  end

  # rubocop:disable Metrics/MethodLength
  def display_welcome
    clear_screen()
    puts ""
    puts "** Welcome to #{WIN_THRESHOLD}! **".center(30)
    puts ''
    prompt "Each card has a point value:"
    prompt "Number cards are worth face value."
    prompt "Face cards are worth 10."
    prompt "Aces are worth 11, unless the sum of the hand" \
      " is greater than #{WIN_THRESHOLD}."
    prompt "Then an ace is worth 1."
    prompt "The dealer will stay at #{STAY_THRESHOLD} or above."
    prompt "The winner of each hand is the closest to" \
      " #{WIN_THRESHOLD} points without going over."
    prompt "The winner of #{ROUNDS} hand#{'s' if ROUNDS > 1} is the champion!"
    puts ''
    press_to_continue()
  end
  # rubocop:enable Metrics/MethodLength

  def display_rounds_won
    puts "* Best of #{ROUNDS} *".center(23)
    puts DECORATION
    puts "#{player.name}: #{player.score}".center(23)
    puts "#{dealer.name}: #{dealer.score}".center(23)
    puts DECORATION
    puts ''
  end

  def clear_screen
    system('clear') || system('cls')
  end

  def press_to_continue
    prompt "Press any key to continue..."
    STDIN.getch
  end

  # rubocop:disable Metrics/AbcSize
  # I think the logic is clear for this method, I tried breaking out the check
  # for busted into a separate method but it didn't really make sense.
  def display_result
    if player.busted?
      prompt "#{player.name} busted. #{player.name} loses this hand."
    elsif dealer.busted?
      prompt "#{dealer.name} busted. #{player.name} wins this hand!"
    elsif find_winner
      display_hand(player)
      display_hand(dealer)
      prompt "#{find_winner.name} wins this hand!"
    else
      prompt "This hand is a draw."
    end
    press_to_continue()
  end
  # rubocop:enable Metrics/AbcSize

  def find_winner # returns player, dealer, or nil
    return player if dealer.busted?
    return dealer if player.busted?
    case player.hand_total <=> dealer.hand_total
    when -1
      dealer
    when 1
      player
    when 0
      nil
    end
  end

  def increment_score
    find_winner.score += 1 if find_winner
  end

  def display_initial_dealer_hand
    upcard = dealer.hand.first
    prompt "#{dealer.name}'s upcard is #{upcard}."
  end

  def display_dealer_hole_card
    prompt "#{dealer.name} flips over the hole card."
    display_hand(dealer)
  end

  def display_hand(participant)
    prompt "#{participant.name} has "\
    "#{participant.join_cards(participant.hand)}."
    print_hand_total(participant)
  end

  def deal_initial_hand
    prompt "Dealing..."
    sleep(1.5)

    2.times do
      deck.deal(player)
      deck.deal(dealer)
    end
  end

  def print_hand_total(participant)
    participant.ace_value!
    prompt "#{participant.name}'s point total is #{participant.hand_total}."
  end

  def player_stays?
    loop do
      prompt "Would you like to hit ('h') or stay ('s')?"
      response = gets.chomp.downcase
      return false if response == 'h'
      return true if response == 's'
      prompt "Sorry, that's not a valid input."
    end
  end

  def dealer_stays?
    dealer.hand_total >= STAY_THRESHOLD
  end

  def dealer_turn
    display_dealer_hole_card
    loop do
      if dealer_stays?
        prompt "#{dealer.name} stays."
        puts ''
        sleep(1.5)
        break
      end
      prompt "#{dealer.name} hits..."
      deal_and_display_hand(dealer)
      break if dealer.busted?
    end
  end

  def deal_and_display_hand(participant)
    deck.deal(participant)
    sleep(1.5)
    display_hand(participant)
    sleep(1.5)
  end

  def player_turn
    loop do
      if player_stays?
        prompt "#{player.name} decided to stay. Dealer's turn!"
        puts ''
        sleep(1.5)
        break
      end
      prompt "#{player.name} decided to hit."
      prompt "Dealing..."
      deal_and_display_hand(player)
      break if player.busted?
    end
  end
end

Game.new.start
