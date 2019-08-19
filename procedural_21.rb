require 'io/console'

SUITS = %w[hearts clubs spades diamonds]
FACE_CARDS = %w[jack queen king]
FACE_VALUES = 10
ACE_VALUES = [1, 11]
NUMBER_CARDS = *(2..9).map(&:to_s)
ALL_CARDS = NUMBER_CARDS + FACE_CARDS + ['ace']
DECK = ALL_CARDS.product(SUITS)
TAKE_AN = ['8', 'ce']
ROUNDS = 2
WIN_THRESHOLD = 21
STAY_THRESHOLD = (WIN_THRESHOLD * 0.81).to_i
DECORATION = "=-=-=-=-=-=-=-=-=-=-=-="

def initialize_deck
  deck_hash =
    DECK.each_with_object({}) do |card, hash|
      hash[card] =
        if NUMBER_CARDS.include?(card[0])
          card[0].to_i
        elsif FACE_CARDS.include?(card[0])
          FACE_VALUES
        elsif card[0] == 'ace'
          11
        end
    end
  deck_hash.to_a.shuffle.to_h
end

def deal_card!(hand, current_deck)
  key, value = current_deck.first
  hand[key] = value
  current_deck.delete(current_deck.first[0])
end

def indefinite_article(card)
  if TAKE_AN.include?(card)
    'an'
  else
    'a'
  end
end

def display_player_hand(hand)
  prompt "You have #{join_cards(hand)}."
  display_points(hand, 'player')
end

def display_dealer_hand(hand)
  prompt "The dealer has #{join_cards(hand)}."
  display_points(hand, 'dealer')
end

def display_initial_dealer_hand(hand)
  upcard = hand.first
  prompt "The dealer's upcard is #{indefinite_article(upcard[0][0])} " \
  "#{upcard[0][0]} of #{upcard[0][1]}."
end

def display_points(hand, player)
  if player == 'player'
    prompt "Your point total is #{hand_value(hand)}."
  elsif player == 'dealer'
    prompt "The dealer's point total is #{hand_value(hand)}."
  end
end

def join_cards(hand)
  end_string = 'and '
  cards = hand.keys.map do |card|
    "#{indefinite_article(card[0])} #{card[0]} of #{card[1]}"
  end
  case cards.size
  when 2
    cards.join(' ' + end_string)
  else
    cards[-1].insert(0, end_string)
    cards.join(', ')
  end
end

def stay?
  loop do
    prompt "Would you like to hit ('h') or stay ('s')?"
    response = gets.chomp.downcase
    if response == 'h'
      return false
    elsif response == 's'
      return true
    else
      prompt "That's not a valid input."
    end
  end
end

def bust?(hand)
  hand_value(hand) > WIN_THRESHOLD
end

def display_bust(hands)
  if bust?(hands[:player])
    prompt "You busted."
  elsif bust?(hands[:dealer])
    prompt "The dealer busted."
  end
end

def detect_winner(hands)
  if hand_value(hands[:dealer]) > hand_value(hands[:player])
    'Dealer'
  elsif hand_value(hands[:dealer]) < hand_value(hands[:player])
    'Player'
  else
    'Push'
  end
end

def display_winner(winner)
  case winner
  when 'Push'
    prompt "It's a push!"
  when 'Dealer'
    prompt "The dealer wins this hand!"
  else
    prompt 'You win this hand!'
  end
end

def ace_value!(hand)
  if hand.values.include?(11)
    until hand_value(hand) <= WIN_THRESHOLD
      ace = hand.select { |_, value| value == 11 }
      hand.delete(ace.keys[0])
      hand[ace.keys[0]] = 1
    end
  end
end

def hand_value(hand)
  hand.values.inject(:+)
end

def prompt(message)
  puts "=> #{message}"
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

def display_rounds_won(wins)
  puts "* Best of #{ROUNDS} *".center(23)
  puts DECORATION
  puts "Player: #{wins.fetch_values(:player).inject(:+)}".center(23)
  puts "Dealer: #{wins.fetch_values(:dealer).inject(:+)}".center(23)
  puts DECORATION
  puts ''
end

def increment_score!(wins, winner)
  wins[winner.downcase.to_sym] += 1
end

def end_round(winner, wins, hands)
  increment_score!(wins, winner)
  system 'clear'
  display_rounds_won(wins)
  puts ''
  display_player_hand(hands[:player])
  display_dealer_hand(hands[:dealer])
  display_bust(hands)
  display_winner(winner)
  unless champion?(wins)
    prompt "Press any key to deal the next hand..."
    STDIN.getch
    system 'clear'
  end
  true
end

def champion?(wins)
  wins.fetch_values(:player).inject(:+) == ROUNDS ||
    wins.fetch_values(:dealer).inject(:+) == ROUNDS
end

def hand_over?(winner, wins, hands)
  if winner
    end_round(winner, wins, hands)
  else
    return false
  end
  true
end

def declare_champion?(winner, wins)
  puts DECORATION
  prompt "The #{winner.downcase} is the champion of this round!"
  if play_again?
    wins[:player] = 0
    wins[:dealer] = 0
  else
    return false
  end
  true
end

# Game loop
system 'clear'
puts ''
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
prompt "The winner of #{ROUNDS} hands is the champion!"
puts ''
prompt "Press any key to start..."
STDIN.getch

wins = { player: 0, dealer: 0 }

loop do
  current_deck = initialize_deck
  winner = nil
  hands = { player: {}, dealer: {} }
  2.times do
    deal_card!(hands[:player], current_deck)
    deal_card!(hands[:dealer], current_deck)
  end

  system 'clear'
  display_rounds_won(wins)
  prompt "Dealing..."
  sleep(1.5)

  ace_value!(hands[:player])
  display_player_hand(hands[:player])
  display_initial_dealer_hand(hands[:dealer])

  # Player turn
  loop do
    break if stay?
    prompt "You decided to hit."
    prompt "Dealing..."
    sleep(1.5)
    deal_card!(hands[:player], current_deck)
    ace_value!(hands[:player])
    display_player_hand(hands[:player]) unless bust?(hands[:player])
    if bust?(hands[:player])
      winner = 'Dealer'
      break
    end
    display_initial_dealer_hand(hands[:dealer])
  end

  if hand_over?(winner, wins, hands)
    if champion?(wins)
      if declare_champion?(winner, wins)
        next
      else
        break
      end
    end
    next
  end

  prompt "You decided to stay. Dealer's turn!"
  puts ''
  sleep(2)

  # Dealer turn
  prompt "The dealer flips over the hole card."
  display_dealer_hand(hands[:dealer])
  sleep(2.5)

  until hand_value(hands[:dealer]) >= STAY_THRESHOLD
    prompt "The dealer hits."
    sleep(1)
    prompt 'Dealing...'
    sleep(1.5)
    deal_card!(hands[:dealer], current_deck)
    ace_value!(hands[:dealer])
    display_dealer_hand(hands[:dealer]) unless bust?(hands[:dealer])
    sleep(2)
    if bust?(hands[:dealer])
      winner = 'Player'
      break
    end
  end

  if hand_over?(winner, wins, hands)
    if champion?(wins)
      if declare_champion?(winner, wins)
        next
      else
        break
      end
    end
    next
  end

  prompt "The dealer stays." unless bust?(hands[:dealer])
  puts ''
  sleep(2)
  winner = detect_winner(hands)

  if hand_over?(winner, wins, hands)
    if champion?(wins)
      if declare_champion?(winner, wins)
        next
      else
        break
      end
    end
    next
  end
end
prompt "Thanks for playing #{WIN_THRESHOLD}!"
