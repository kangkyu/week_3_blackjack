require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  def count_points(cards)
    # total = count_points(session[:player_hand])
    total = 0
    arr = cards.collect{|e| e[1]}
    arr.each do |v|
      if v == 'A'
        total += 11
      else
        total += v.to_i == 0 ? 10 : v.to_i
      end
    end
    arr.select{|e| e=='A'}.count.times do
      break if total <= 21
      total -= 10
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
    redirect '/game' 
  else
    redirect '/new_user'
  end
end

get '/game' do
  session[:deck] = ['D','S','H','C'].product(['2','3','4','5','6','7','8','9','10','A','Q','K','J']).shuffle!
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop

  if count_points(session[:player_hand]) == 21
      @success = "#{session[:user_name]} won Black Jack!"
      @show_hit_button = false
  end
  erb :game
end

post '/game' do
  "Hello World - post game page"
  if params[:hit_or_stay] == 'hit'
    redirect '/hit'
  else
    redirect '/stay'
  end
end

get '/hit' do
  session[:player_hand] << session[:deck].pop

  if count_points(session[:player_hand]) >= 21
    if count_points(session[:player_hand]) == 21
      @success = "#{session[:user_name]} won Black Jack!"
    else # if player_points > 21
      @error = "Sorry but #{session[:user_name]} got Busted!"
    end
    @show_hit_button = false
  end

  erb :game #re-render the screen
end
  
get '/stay' do
  # @show_hit_button = false
  # dealer's turn

  erb :game
end

get '/new_user' do
  "this is new user"
  erb :new_user
end

post '/new_user' do
  session[:user_name] = params[:user_name].capitalize

  redirect '/game'
end

before do
  @show_hit_button = true
end
