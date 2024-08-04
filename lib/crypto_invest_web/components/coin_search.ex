defmodule CryptoInvestWeb.CoinSearch do
  @moduledoc """
  Handles searching for coins and retrieving their data.
  """

  alias HTTPoison
  alias Jason
  require Logger

  @coingecko_base_url "https://api.coingecko.com/api/v3"
  @seconds_in_day 24 * 60 * 60

  @http_client Application.get_env(:crypto_invest_web, :http_client, HTTPoison)
  @facebook_client Application.get_env(:crypto_invest_web, :facebook_client, CryptoInvestWeb.Facebook)

  def search_coin_by_name(sender_id, coin_name) do
    :ets.insert(:user_states, {sender_id, :awaiting_coin_id_to_search})

    url = "#{@coingecko_base_url}/search?query=#{URI.encode(coin_name)}"

    case @http_client.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"coins" => coins}} when length(coins) > 0 ->
            quick_replies = 
              coins
              |> Enum.take(5)
              |> Enum.map(fn coin ->
                %{
                  content_type: "text",
                  title: coin["name"],
                  payload: coin["id"],
                }
              end)

            body = %{
              recipient: %{id: sender_id},
              message: %{
                text: "Please select a coin by choosing an option below:",
                quick_replies: quick_replies
              }
            }
            @facebook_client.send_quick_replies_message(sender_id, body)
          _ ->
            @facebook_client.send_message(sender_id, "No coins found with that name.")
        end
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Error searching for coin: #{reason}")
        @facebook_client.send_message(sender_id, "Error searching for coin.")
    end
  end

  def search_coin_by_id(sender_id, coin_id) do
    :ets.insert(:user_states, {sender_id, :awaiting_coin_id_to_search_result})

    endpoint = "#{@coingecko_base_url}/coins/#{coin_id}/market_chart/range"
    {start, endtime} = interval_start_and_end()
    params = [vs_currency: "usd", to: endtime, from: start]
    url = "#{endpoint}?#{URI.encode_query(params)}"
    response = @http_client.get(url)

    case response do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"prices" => prices}} when length(prices) > 0 ->
            prices_str =
              prices
              |> Enum.map(fn [timestamp, price] ->
                {DateTime.from_unix!(div(timestamp, 1000)) |> DateTime.to_date(), price}
              end)
              |> Enum.reduce(%{}, fn {date, price}, acc ->
                Map.put(acc, date, price)  # This keeps the last price for each unique date
              end)
              |> Enum.map(fn {date, price} ->
                formatted_price = :erlang.float_to_binary(price, [decimals: 4])
                "#{date}: $#{formatted_price}"
              end)
              |> Enum.join("\n")

            @facebook_client.send_message(sender_id, "Prices for the last 14 days:\n#{prices_str}")

          {:ok, _} ->
            @facebook_client.send_message(sender_id, "No price data found for that coin.")

          {:error, decode_error} ->
            Logger.error("Error decoding response: #{decode_error}")
            @facebook_client.send_message(sender_id, "Error decoding price data.")
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Error fetching coin prices: #{reason}")
        @facebook_client.send_message(sender_id, "Error fetching coin prices.")
    end
  end

  defp interval_start_and_end do
    now = DateTime.utc_now()  # Get the current UTC date and time

    # Calculate the Unix timestamp for the start of the interval (14 days ago)
    start_datetime = DateTime.add(now, -14 * @seconds_in_day, :second)
    start_timestamp = DateTime.to_unix(start_datetime, :second)

    # Calculate the Unix timestamp for the end of the interval (today)
    end_timestamp = DateTime.to_unix(now, :second)

    {start_timestamp, end_timestamp}
  end
end
