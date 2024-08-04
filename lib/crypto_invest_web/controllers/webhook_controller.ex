defmodule CryptoInvestWeb.WebhookController do
  use CryptoInvestWeb, :controller

  alias HTTPoison
  alias Jason
  require Logger
  alias CryptoInvestWeb.Constants

  @verify_token "facebook token"

  # Use dependency injection for testing
  @facebook Application.get_env(:crypto_invest, :facebook_module, CryptoInvestWeb.Facebook)
  @coin_search Application.get_env(:crypto_invest, :coin_search_module, CryptoInvestWeb.CoinSearch)

  def verify(conn, %{"hub.mode" => "subscribe", "hub.verify_token" => verify_token, "hub.challenge" => challenge}) do
    if verify_token == @verify_token do
      send_resp(conn, 200, challenge)
    else
      send_resp(conn, 403, "Forbidden")
    end
  end

  def handle(conn, %{"object" => "page", "entry" => entries}) do
    for %{"messaging" => messaging_events} <- entries do
      for event <- messaging_events do
        # Handle postbacks
        if Map.has_key?(event, "postback") do
          %{"sender" => %{"id" => sender_id}, "postback" => %{"payload" => payload}} = event
          handle_postback(sender_id, payload)
        end
        
        # Handle quick replies
        if Map.has_key?(event, "message") and Map.has_key?(event["message"], "quick_reply") do
          %{"sender" => %{"id" => sender_id}, "message" => %{"quick_reply" => %{"payload" => payload}}} = event
          case :ets.lookup(:user_states, sender_id) do
          [{^sender_id, :awaiting_coin_id_to_search}] ->
            @coin_search.search_coin_by_id(sender_id, payload)
          _ ->
            IO.puts("test new")
          end
        end

        # Handle messages sent by the user
        if Map.has_key?(event, "message") and Map.has_key?(event["message"], "text") do
          %{"sender" => %{"id" => sender_id}, "message" => %{"text" => text}} = event
          case :ets.lookup(:user_states, sender_id) do
            [{^sender_id, :awaiting_coin_name_search}] ->
              :ets.insert(:user_states, {sender_id, :awaiting_coin_name})
            [{^sender_id, :awaiting_coin_id_search}] ->
              :ets.insert(:user_states, {sender_id, :awaiting_coin_id})
            _ ->
              IO.puts "i m out"
          end
          handle_message(sender_id, text)
        end
      end
    end

    send_resp(conn, 200, "EVENT_RECEIVED")
  end

  defp handle_postback(sender_id, "GET_STARTED") do
    :ets.insert(:user_states, {sender_id, :started_coin_search})
    @facebook.send_user_first_name(sender_id)
  end

  defp handle_postback(sender_id, "SEARCH_BY_NAME") do
    :ets.insert(:user_states, {sender_id, :awaiting_coin_name_search})
    @facebook.send_message(sender_id, "Please type the name of the coin you want to search for.")
  end

  defp handle_postback(sender_id, "SEARCH_BY_COIN") do
    :ets.insert(:user_states, {sender_id, :awaiting_coin_id_search})
    @facebook.send_message(sender_id, "Please type the id of the coin you want to search for.")
  end

  defp handle_message(sender_id, text) do
    case :ets.lookup(:user_states, sender_id) do
      [{^sender_id, :awaiting_coin_name}] ->
        @coin_search.search_coin_by_name(sender_id, text)

      [{^sender_id, :awaiting_coin_id}] ->
        @coin_search.search_coin_by_id(sender_id, text)
      
      [{^sender_id, :awaiting_coin_id_to_search}] ->
        @coin_search.search_coin_by_id(sender_id, text)

      _ ->
        case String.trim(text) do
          "Search by Name" -> 
            @facebook.send_message(sender_id, "Please type the name of the coin you want to search for.")
            :ets.insert(:user_states, {sender_id, :awaiting_coin_name})

          "Search by Coin" ->
            @facebook.send_message(sender_id, "Please type the id of the coin you want to search for.")
            :ets.insert(:user_states, {sender_id, :awaiting_coin_id})
          
          _ ->
            handle_coin_search(sender_id, text)
        end
    end
  end

  defp handle_coin_search(sender_id, query) do
    case String.split(query, " ", parts: 2) do
      ["search", coin_name] ->
        @coin_search.search_coin_by_name(sender_id, coin_name)
      ["search", coin_name] ->
        @coin_search.search_coin_by_id(sender_id, query)
      _ ->
        IO.puts("no action perform")
    end
  end
end
