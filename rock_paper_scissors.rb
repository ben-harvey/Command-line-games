VALID_CHOICES = %w(rock paper scissors spock lizard)
SHORT_CHOICES = %w(ro pa sc sp li)
RULES = { paperrock: 'paper', paperscissors: 'scissors',
          paperspock: 'paper', lizardpaper: 'lizard',
          rockscissors: 'rock', rockspock: 'spock',
          lizardrock: 'rock', lizardspock: 'lizard',
          lizardscissors: 'scissors', scissorsspock: 'spock' }

def clear_screen
  system('clear') || system('cls')
end

def prompt(message)
  puts("=> #{message}")
end

def user_choice
  loop do
    prompt("Choose one: #{VALID_CHOICES.join(', ')}")
    prompt("Or, enter the first two letters of your choice."\
    " E.g. 'sp' for spock")
    choice = gets.chomp.downcase
    if SHORT_CHOICES.include?(choice)
      choice = VALID_CHOICES[SHORT_CHOICES.index(choice)]
      return choice
    elsif VALID_CHOICES.include?(choice)
      return choice
    else
      prompt("That's not a valid choice.")
    end
  end
end

def winner?(player_choice, computer_choice)
  return 'tie' if player_choice == computer_choice
  check_winner = [player_choice, computer_choice].sort.join.to_sym
  winner = RULES.fetch(check_winner)
  if winner == player_choice
    true
  else
    false
  end
end

def display_score(player_wins, computer_wins)
  puts "You have won #{player_wins}. Computer has won #{computer_wins}."
end

loop do
  clear_screen

  player_wins = 0
  computer_wins = 0
  player_choice = nil
  grand_winner = nil

  prompt("Welcome to Rock Paper Scissors Spock Lizard!")
  prompt("Whoever wins five rounds is the grand winner.")

  loop do
    player_choice = user_choice
    computer_choice = VALID_CHOICES.sample
    clear_screen
    prompt("You chose #{player_choice}; Computer chose #{computer_choice}.")

    round_winner = winner?(player_choice, computer_choice)

    if round_winner == 'tie'
      prompt("It's a tie.")
    elsif round_winner
      prompt('You win!')
      player_wins += 1
    else
      prompt('You lose.')
      computer_wins += 1
    end

    display_score(player_wins, computer_wins)

    if player_wins == 5
      grand_winner = 'You are'
      break
    elsif computer_wins == 5
      grand_winner = 'Computer is'
      break
    end
  end

  prompt("#{grand_winner} the grand winner!")
  prompt("Would you like to play again? Enter 'y' for yes"\
          " or 'x' to exit")

  exit_program = false
  loop do
    answer = gets.chomp.downcase
    if answer == 'y'
      clear_screen
      break
    elsif answer == 'x'
      exit_program = true
      break
    else
      prompt("Invalid input. Please enter 'y' for yes"\
              " or 'x' to exit)")
    end
  end
  break if exit_program
end

clear_screen
prompt("Thanks for playing! Goodbye.")
