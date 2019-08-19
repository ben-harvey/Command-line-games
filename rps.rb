NOUNS = ["trousers", "cough", "trip", "hands", "wound", "pigs", "carriage",
         "shirt", "territory", "blade", "string", "error", "effect", "touch",
         "watch", "locket", "swim", "structure", "minister", "hole", "dock",
         "arch", "underwear", "summer", "eye", "rake", "screw", "cherries",
         "basketball", "can", "metal", "dogs", "key", "taste", "whistle",
         "leather", "pig", "plate", "scent", "boundary", "passenger", "plot",
         "adjustment", "cattle", "needle", "authority", "ocean", "quince",
         "range", "oatmeal", "root", "bridge", "flag", "whip", "cub",
         "protest", "quicksand", "stream", "reading", "thought", "frogs",
         "belief", "profit", "society", "soup", "sock", "button", "run",
         "exchange", "pies", "way", "camp", "skate", "pear", "shape", "tax",
         "hall", "brake", "country", "water", "reward", "jeans", "invention",
         "ducks", "crime", "pipe", "pollution", "duck", "song", "produce",
         "marble", "title", "creature", "fish", "toad", "wool", "skin",
         "spark", "plants", "afterthought"]

module Promptable
  def prompt(message)
    puts "=> #{message}"
  end
end

class Player
  include Promptable

  attr_accessor :move, :name, :score

  def initialize
    set_name
    @score = 0
  end
end

class Human < Player
  def set_name
    n = nil
    loop do
      prompt "Hi there, what's your name?"
      n = gets.chomp
      break unless n.delete(' ').empty?
      prompt "Sorry, must enter a value."
    end
    self.name = n.capitalize
  end

  def prompt_for_choice(valid_choices)
    prompt("Choose one: #{valid_choices.join(', ')}")
    prompt("Or, enter the first two letters of your choice."\
      " E.g. 'sc' for scissors")
  end

  def look_up_choice(short_choices, valid_choices, choice)
    if short_choices.include?(choice)
      choice = valid_choices[short_choices.index(choice)]
      choice
    elsif valid_choices.include?(choice)
      choice
    end
  end

  def choose(rule_type)
    choice = nil
    short_choices = rule_type.class::SHORT_CHOICES
    valid_choices = rule_type.class::VALID_CHOICES
    loop do
      prompt_for_choice(valid_choices)
      choice = gets.chomp.downcase
      choice = look_up_choice(short_choices, valid_choices, choice)
      if choice
        self.move = choice
        break
      else
        prompt("That's not a valid choice.")
      end
    end
  end
end

class Computer < Player # chooses randomly from available moves
  def set_name
    self.name = ['GoBot', 'Optimus Prime', 'Johnny 5'].sample
  end

  def choose(_, _, _, rule_type)
    choice = rule_type.class::VALID_CHOICES.sample
    self.move = choice
  end
end

class ScissorsBot < Computer # applies human-psychology-based ai
  # https://www.youtube.com/watch?v=rudzYPHuewc
  def set_name
    self.name = "ScissorsBot"
  end

  def will_beat(move, rule_type)
    choices = rule_type.class::RULES.values.select do |arr|
      arr.last.split(/[ .]/).last.downcase == move
    end
    choices.map(&:first)
  end

  def get_computer_choice(rule_type, computer_move)
    human_will_choose = will_beat(computer_move, rule_type)
    computer_choices = []
    human_will_choose.each do |choice|
      computer_choices << will_beat(choice, rule_type)
    end
    computer_choices.flatten!
    computer_choices.max_by do |choice|
      computer_choices.count(choice)
    end
  end

  def choose(human_move, computer_move, winner, rule_type)
    self.move = case winner
                when :computer
                  get_computer_choice(rule_type, computer_move)
                when :human
                  computer_choices = will_beat(human_move, rule_type)
                  computer_choices.sample
                when :tie
                  rule_type.class::VALID_CHOICES.sample
                end
  end
end

class CopyBot < Computer # copies player's last move
  def set_name
    self.name = "Copybot"
  end

  def choose(human_move, _, _, _)
    self.move = human_move
  end
end

class Terminator < Computer # always plays dynamite, always wins
  def set_name
    self.name = "Terminator"
  end

  def choose(_, _, _, _)
    self.move = 'dynamite'
  end
end

class RandoBot < Computer # samples from NOUNS, always loses
  def set_name
    self.name = "Randobot"
  end

  def choose(_, _, _, _)
    self.move = NOUNS.sample
  end
end

# class Move
#   include Comparable

#   def to_s
#     self.class.name.downcase
#   end
# end

# class Rock < Move

#   def <=>(other)
#     if [Scissors, Lizard].include?(other)
#       -1
#     elsif other == self
#       0
#     else
#       1
#     end
#   end
# end

# class Paper < Move
#   def <=>(other)
#     if [Rock, Spock].include?(other)
#       -1
#     elsif other == self
#       0
#     else
#       1
#     end
#   end
# end

# class Scissors < Move
#   def <=>(other)
#     if [Rock, Lizard].include?(other)
#       -1
#     elsif other == self
#       0
#     else
#       1
#     end
#   end
# end

# class Lizard < Move
#   def <=>(other)
#     if [Paper, Spock].include?(other)
#       -1
#     elsif other == self
#       0
#     else
#       1
#     end
#   end
# end

# class Spock < Move
#   def <=>(other)
#     if [Rock, Scissors].include?(other)
#       -1
#     elsif other == self
#       0
#     else
#       1
#     end
#   end
# end

class History
  attr_accessor :human_rps, :computer_rps, :human_rpsls, :computer_rpsls

  def initialize
    @human_rps = []
    @computer_rps = []
    @human_rpsls = []
    @computer_rpsls = []
  end
end

class RpsRules
  include Promptable

  VALID_CHOICES = %w[rock paper scissors]
  SHORT_CHOICES = %w[ro pa sc]
  RULES = {
    paperrock: ['paper', "Paper covers rock."],
    paperscissors: ['scissors', "Scissors cut paper."],
    rockscissors: ['rock', "Rock crushes scissors."]
  }

  def to_s
    "Rock Paper Scissors"
  end

  def print_rules
    RULES.values.each do |_, rule|
      prompt rule
    end
  end
end

class RpslsRules
  include Promptable

  VALID_CHOICES = %w[rock paper scissors spock lizard]
  SHORT_CHOICES = %w[ro pa sc sp li]
  RULES = {
    paperrock: ['paper', "Paper covers rock."],
    paperscissors: ['scissors', "Scissors cut paper."],
    paperspock: ['paper', "Paper disproves Spock."],
    lizardpaper: ['lizard', "Lizard eats paper."],
    rockscissors: ['rock', "Rock crushes scissors."],
    rockspock: ['spock', "Spock vaporizes rock."],
    lizardrock: ['rock', "Rock crushes lizard."],
    lizardspock: ['lizard', "Lizard poisons Spock."],
    lizardscissors: ['scissors', "Scissors decapitate lizard."],
    scissorsspock: ['spock', "Spock smashes scissors."]
  }
  def to_s
    "Rock Paper Scissors Lizard Spock"
  end

  def print_rules
    RULES.values.each do |_, rule|
      prompt rule
    end
  end
end

class RPSGame ##########################################################
  include Promptable

  attr_accessor :human, :computer, :rule_type, :winner, :history

  def initialize
    clear_screen
    @human = Human.new()
    set_computer_player
    @winner = :human
    @history = History.new
  end

  def set_computer_player
    personalities = [
      'Computer', 'ScissorsBot', 'Terminator', 'CopyBot', 'RandoBot'
    ]
    @computer = Module.const_get(personalities.sample).new
  end

  def display_welcome_message
    prompt "Welcome to #{rule_type}, #{human.name}!"
  end

  def verify_limit?(answer)
    answer.to_s.to_i == answer.to_i && answer > 0
  end

  def set_score_limit
    prompt "How many rounds would you like to play in this match?"
    @limit = nil
    loop do
      answer = gets.chomp.to_i
      if verify_limit?(answer)
        @limit = answer
        break
      else
        prompt "Sorry, please enter a whole number greater than zero!"
      end
    end
    clear_screen
    prompt "Great, the first to win #{@limit} "\
    "#{@limit > 1 ? 'rounds' : 'round'} is the grand champ!"
  end

  def prompt_rule_type
    clear_screen
    prompt "Would you like to play:"
    prompt "1) Rock Paper Scissors, or "
    prompt "2) Rock Paper Scissors Lizard Spock?"
    prompt "Please enter 1 or 2: "
  end

  def set_rule_type
    prompt_rule_type
    answer = nil
    loop do
      answer = gets.chomp
      break if ['1', '2'].include? answer
      prompt "Please enter 1 or 2!"
    end
    self.rule_type = answer == "1" ? RpsRules.new : RpslsRules.new
  end

  def display_goodbye_message
    prompt "Thanks for playing Rock Paper Scissors (Lizard Spock). Goodbye!"
  end

  def display_choices
    prompt "#{human.name} chose #{human.move}."
    prompt "#{computer.name} chose #{computer.move}."
  end

  def find_winning_move
    check_winner = [human.move, computer.move].sort.join.to_sym
    return nil unless rule_type.class::RULES.keys.include?(check_winner)
    rule_type.class::RULES.fetch(check_winner)
  end

  def find_winner
    return :computer if computer.move == 'dynamite'
    return :tie if human.move == computer.move
    @winning_move = find_winning_move
    if @winning_move.nil?
      :human
    elsif @winning_move.first == human.move
      :human
    else
      :computer
    end
  end

  def prompt_computer_winner
    if computer.move == 'dynamite'
      prompt 'BOOM!'
    else
      prompt @winning_move.last.to_s
    end
    prompt "#{computer.name} wins!"
  end

  # rubocop:disable Metrics/AbcSize
  # I feel like the logic in this method is really straightforward
  def display_winner
    case find_winner
    when :tie
      prompt "It's a tie!"
    when :human
      if @winning_move.nil?
        prompt "#{human.move.capitalize} beats #{computer.move}."
      else
        prompt @winning_move.last.to_s
      end
      prompt "#{human.name} wins!"
      human.score += 1
    when :computer
      prompt_computer_winner
      computer.score += 1
    end
  end
  # rubocop:enable Metrics/AbcSize

  def display_score
    prompt "The score is #{human.name}: #{human.score} "\
    "and #{computer.name}: #{computer.score}."
  end

  def display_champ
    if human.score > computer.score
      prompt "#{human.name} is the grand champ! #{human.name} rocks! "\
      "(pun intended)"
    else
      prompt "#{computer.name} is the grand champ!"
    end
  end

  def stop_play?
    human.score == @limit || computer.score == @limit
  end

  def play_again?
    prompt "Would you like to play another match? (y/n)"
    answer = nil
    loop do
      answer = gets.chomp
      break if ['y', 'n'].include?(answer.downcase)
      prompt "Sorry, please enter y or n."
    end
    return true if answer.downcase == 'y'
    false
  end

  def clear_screen
    system("clear") || system("cls")
  end

  def reset_score
    human.score = 0
    computer.score = 0
  end

  def show_rules
    prompt "Here are the rules of the game: "
    rule_type.print_rules
  end

  def set_initial_moves
    @computer.move = 'rock'
    @human.move = 'rock'
  end

  # rubocop:disable Metrics/AbcSize
  # refactoring with ternary expressions didn't satisfy the cop and maybe
  # made the method harder to understand?
  def add_choices_to_history
    player_history =
      rule_type.is_a?(RpsRules) ? history.human_rps : history.human_rpsls
    computer_history =
      rule_type.is_a?(RpsRules) ? history.computer_rps : history.computer_rpsls
    player_history << human.move
    computer_history << computer.move

    # if rule_type.is_a?(RpsRules)
    #   history.player_rps << human.move
    #   history.computer_rps << computer.move
    # elsif rule_type.is_a?(RpslsRules)
    #   history.player_rpsls << human.move
    #   history.computer_rpsls << computer.move
    # end
  end
  # rubocop:enable Metrics/AbcSize

  def display_history
    prompt "Rock Paper Scissors moves (player, computer): "
    history.human_rps.zip(history.computer_rps).each do |p, c|
      puts "(#{p}, #{c})"
    end
    puts ''
    prompt "Rock Paper Scissors Lizard Spock moves (player, computer): "
    history.human_rpsls.zip(history.computer_rpsls).each do |p, c|
      puts "(#{p}, #{c})"
    end
  end

  def prompt_for_move_history
    prompt "Would you like to view the move history for your matches? (y/n)"
    answer = nil
    loop do
      answer = gets.chomp
      break if ['y', 'n'].include?(answer.downcase)
      prompt "Sorry, please enter y or n."
    end
    display_history if answer.downcase == 'y'
  end

  def initialize_gameplay
    set_computer_player
    set_initial_moves
    reset_score
  end

  def play_matches
    computer.choose(human.move, computer.move, winner, rule_type)
    human.choose(rule_type)
    add_choices_to_history
    display_choices
    @winner = find_winner
    display_winner
    display_score
  end

  def set_rules_and_score_limit
    set_rule_type
    display_welcome_message
    show_rules
    set_score_limit
  end

  def gameplay
    clear_screen
    loop do
      initialize_gameplay
      set_rules_and_score_limit
      loop do
        play_matches
        break if stop_play?
      end
      display_champ
      break unless play_again?
    end
    prompt_for_move_history
    display_goodbye_message
  end
end

RPSGame.new.gameplay
