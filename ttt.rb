class Board
  attr_reader :squares

  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]] # diagonals

  def initialize
    @squares = {}
    reset
  end

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def identical_markers?(squares, count)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != count
    markers.min == markers.max
  end

  # returns winning marker or nil
  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if identical_markers?(squares, 3)
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts "     |     |"
    puts "  #{squares[1]}  |  #{squares[2]}  |  #{squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{squares[4]}  |  #{squares[5]}  |  #{squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{squares[7]}  |  #{squares[8]}  |  #{squares[9]}"
    puts "     |     |"
  end

  def joinor(array, seperator = ', ', end_string = ' or')
    case array.size
    when 1
      array[0]
    when 2
      array.join("#{end_string} ")
    else
      array.join(seperator).insert(-3, end_string)
    end
  end
end
# rubocop:enable Metrics/AbcSize

class Square
  attr_accessor :marker

  INITIAL_MARKER = " "

  def initialize
    @marker = INITIAL_MARKER
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_accessor :score, :marker, :name

  def initialize(marker, name)
    @marker = marker
    @score = 0
    @name = name
  end
end

class Human < Player
  def move(board)
    puts "Choose a square (#{board.joinor(board.unmarked_keys)})"
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = marker
  end
end

class Computer < Player
  COMPUTER_NAMES = ["KITT", "Rosie", "ED-209", "T-1000", "Iron Giant",
                    "Major Motoko Kusanagi", "Bishop 341-B", "Data"]

  def initialize(marker, name)
    super
    set_computer_name
  end

  def set_computer_name
    self.name = COMPUTER_NAMES.sample
  end

  def move(board, human_marker)
    square = [board.unmarked_keys.sample]
    square = [5] if board.unmarked_keys.include?(5)
    ai_choices = [
      ai_square_choice(board, human_marker),
      ai_square_choice(board, marker)
    ]
    square = if ai_choices[1] # to win
               ai_choices[1]
             elsif ai_choices[0] # to block
               ai_choices[0]
             else
               square # take 5 if not taken, otherwise choose at random
             end

    board[square.first] = marker
  end

  def ai_square_choice(board, marker)
    board.class::WINNING_LINES.each do |line|
      squares = board.squares.values_at(*line)
      if board.identical_markers?(squares, 2) &&
         squares.map(&:marker).include?(marker)
        return board.unmarked_keys.select { |key| line.include?(key) }
      end
    end
    nil
  end
end

class TTTGame
  COMPUTER_MARKER = "O"
  FIRST_TO_MOVE = :human # choose :human or :computer
  GAMES_PER_MATCH = 5

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Human.new(nil, nil)
    @computer = Computer.new(COMPUTER_MARKER, nil)
    @current_player = set_first_player
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # don't want to refactor the main game loop past the point of clarity
  def play
    set_up_first_game
    loop do
      loop do
        clear_screen_and_display_board
        loop do
          play_game
          break if board.someone_won? || board.full?
          clear_screen_and_display_board if human_turn?
        end
        finish_game
        break if winning_player
        reset_game
      end
      display_match_result
      break unless play_again?
      set_up_replay
    end
    display_goodbye_message
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def set_up_first_game
    clear_screen
    display_welcome_message
    choose_player_name
    display_sample_board
    choose_player_marker
  end

  def set_up_replay
    display_play_again_message
    reset_score
    reset_game
  end

  def play_game
    display_score
    current_player_moves(board)
  end

  def finish_game
    display_game_result
    increment_score
  end

  def display_sample_board
    puts "The squares are numbered as follows: "
    puts ''
    puts '     |     |'
    puts "  1  |  2  |  3"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  4  |  5  |  6"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  7  |  8  |  9"
    puts "     |     |"
    puts ''
  end

  def set_first_player
    case FIRST_TO_MOVE
    when :human
      human
    when :computer
      computer
    end
  end

  # returns winning Player object or nil
  def winning_player
    return human if human.score == GAMES_PER_MATCH
    return computer if computer.score == GAMES_PER_MATCH
    nil
  end

  def choose_player_marker
    answer = nil
    loop do
      puts "Your marker can be any single character "\
      "(other than #{computer.marker})"
      puts ""
      puts "Please choose your marker: "
      answer = gets.chomp
      break if answer.delete(' ').size == 1 && answer != computer.marker
      puts "Sorry, you must enter one character that's not #{computer.marker}"
    end
    human.marker = answer
  end

  def choose_player_name
    answer = nil
    loop do
      puts "Please enter your name: "
      answer = gets.chomp.capitalize
      break unless answer.delete(' ').empty?
      puts "Sorry, you must enter at least one character."
    end
    human.name = answer
    puts ""
    puts "Welcome, #{human.name}!"
    puts ""
  end

  def display_score
    puts ""
    puts "#{human.name} wins: #{human.score} | "\
    "#{computer.name} wins: #{computer.score}"
    puts ""
  end

  def increment_score
    case board.winning_marker
    when human.marker
      human.score += 1
    when COMPUTER_MARKER
      computer.score += 1
    end
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts ""
    puts "The first player to win #{GAMES_PER_MATCH} games wins the match."
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing, goodbye!"
  end

  def display_board
    puts ""
    puts "#{human.name}'s marker is #{human.marker}. " \
    "#{computer.name}'s marker is #{COMPUTER_MARKER}."
    puts ""
    board.draw
    puts ""
  end

  def clear_screen_and_display_board
    clear_screen
    display_board
  end

  def human_turn?
    @current_player == human
  end

  def swap_turns
    @current_player = @current_player == human ? computer : human
  end

  def current_player_moves(board)
    if human_turn?
      human.move(board)
    else
      computer.move(board, human.marker)
    end
    swap_turns
  end

  def progress_bar(message)
    progress_bar = "#{message} ."
    puts progress_bar
    3.times do
      sleep(0.6)
      clear_screen_and_display_board
      progress_bar << '.'
      puts progress_bar
    end
  end

  def display_game_result
    clear_screen_and_display_board
    message = case board.winning_marker
              when human.marker
                "#{human.name} won this game!"
              when COMPUTER_MARKER
                "#{computer.name} won this game!"
              else
                "The board is full."
              end
    progress_bar(message)
  end

  def reset_score
    human.score = 0
    computer.score = 0
  end

  def display_match_result
    puts ""
    puts "#{winning_player.name} won #{GAMES_PER_MATCH} games."
    puts "#{winning_player.name} won this match!"
    puts ''
  end

  def clear_screen
    system('clear') || system('cls')
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play another match? (y/n)"
      answer = gets.chomp.downcase
      break if %w[y n].include?(answer)
      puts "Sorry, please enter y or n"
    end
    answer == "y"
  end

  def reset_game
    board.reset
    @current_player = set_first_player
    clear_screen
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end
end

game = TTTGame.new()
game.play
