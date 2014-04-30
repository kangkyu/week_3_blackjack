require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  def count_points(cards)
    # total = count_points(session[:player_hand])

    arr = cards.map{|e| e[1] }

    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0 # J, Q, K
        total += 10
      else
        total += value.to_i
      end
    end

    #correct for Aces
    arr.select{|e| e == "A"}.count.times do
      total -= 10 if total > 21
    end

    total
  end

  def card_file_name(card)
    "#{display(card[0]).downcase}_#{(card[1].to_i == 0 ? display(card[1]) : card[1]).downcase}"
  end

  def card_full_name(card)
    "#{display(card[1])} of #{display(card[0])}"
  end

  def display(suit_or_rank)
    case suit_or_rank
      when 'D' then "Diamonds" 
      when 'C' then "Clubs"
      when 'H' then "Hearts"
      when 'S' then "Spades"
      when '2' then "Two"
      when '3' then "Three"
      when '4' then "Four"
      when '5' then "Five"
      when '6' then "Six"
      when '7' then "Seven"
      when '8' then "Eight"
      when '9' then "Nine"
      when '10' then "Ten"
      when 'J' then "Jack"
      when 'K' then "King"
      when 'Q' then "Queen"
      when 'A' then "Ace"
    end 
  end
end

get '/' do
  if session[:user_name]
    redirect '/welcome' 
  else
    redirect '/new_user'
  end
end

get '/leave' do
  session.clear
  redirect '/'
end

get '/welcome' do
  @success = "Hello #{session[:user_name]}"
  session[:player_balance] ||= 500
  session[:balance_rate] = (session[:player_balance] / 5)

  erb :welcome
end

post '/welcome' do
  if params[:bet_much].to_i < 5
    @error = "a player has to bet minimum or more."
    halt erb(:welcome)
  end
  session[:bet_much] = params[:bet_much].to_i
  if session[:bet_much] > session[:player_balance]
    @error = "bet no more than player's balance"
    halt erb(:welcome)
  end

  redirect '/game'
end

get '/new_user' do
  @show_navbar = false
  erb :new_user
end

post '/new_user' do
  if params[:user_name].empty?
    @error = "name is required"
    @show_navbar = false
    halt erb(:new_user)
  end
  session[:user_name] = params[:user_name].capitalize

  redirect '/welcome'
end

get '/game' do
  session[:deck] = ['D','S','H','C'].product(['2','3','4','5','6','7','8','9','10','A','Q','K','J']).shuffle!
  
  session[:player_hand] = []
  session[:dealer_hand] = []

  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop


  if count_points(session[:player_hand]) == 21
    redirect '/conclude'
    break
  end

  @player_turn = true
  erb :game 
end


post '/game' do
  if params[:hit_or_stay] == 'hit'
    redirect '/hit'
  else
    redirect '/stay'
  end
end

post '/new_round' do
  if params[:new_round] == 'continue'
    redirect '/welcome'
  else
    redirect '/leave'
  end
end

get '/hit' do
  @player_turn = true
  session[:player_hand] << session[:deck].pop
  if count_points(session[:player_hand]) > 21
    # player busts
    redirect '/conclude'
  else
    # still playing, re-render the screen
    erb :game
  end

end
  
get '/stay' do
  # dealer's turn
  redirect '/dealer' 
end

get '/dealer' do
  while count_points(session[:dealer_hand]) < 17
    # dealer hit
    session[:dealer_hand] << session[:deck].pop
    if count_points(session[:dealer_hand]) > 21
      # dealer busts
      redirect '/conclude'
      break
    end  
  end
  # round ends
  redirect '/conclude'
end

get '/conclude' do
  player_total = count_points(session[:player_hand])
  dealer_total = count_points(session[:dealer_hand])

  if player_total == 21 && session[:player_hand].count == 2
    @alert = "#{session[:user_name]} won Black Jack!"
    @player_turn = true
    @win_much = session[:bet_much] * 2
  elsif player_total > 21
    @alert = "#{session[:user_name]} Busts"
    @player_turn = true
    @win_much = session[:bet_much] * -1
  elsif dealer_total > 21
    @alert = "Dealer Busts"
    @win_much = session[:bet_much] * 1
  else # compare stay values
    if player_total > dealer_total
      @alert = "Dealer Stay - #{session[:user_name]} Won"
      @win_much = session[:bet_much] * 1
    elsif player_total < dealer_total
      if dealer_total == 21
        @alert = "Dealer Black Jack - #{session[:user_name]} Lost"
      else
        @alert = "Dealer Stay - #{session[:user_name]} Lost"
      end
        @win_much = session[:bet_much] * -1
    else
      @alert = "Dealer Stay - Round Push."
      @win_much = 0
    end
  end
  session[:player_balance] += (@win_much)

  erb :conclude
end

before do
  @show_navbar = true
  @player_turn = false
end
