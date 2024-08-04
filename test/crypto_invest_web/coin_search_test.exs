defmodule CryptoInvestWeb.CoinSearchTest do
  use ExUnit.Case
  alias CryptoInvestWeb.CoinSearch

  # Custom module to act as HTTP client for testing
  defmodule TestHTTPClient do
    def get(_url) do
      {:ok, %HTTPoison.Response{body: "{}"}}
    end
  end

  # Custom module to act as Facebook client for testing
  defmodule TestFacebookClient do
    def send_quick_replies_message(_sender_id, _body), do: :ok
    def send_message(_sender_id, _message), do: :ok
  end

  setup do
    # Swap out the HTTP client and Facebook client with test implementations
    Application.put_env(:crypto_invest_web, :http_client, TestHTTPClient)
    Application.put_env(:crypto_invest_web, :facebook_client, TestFacebookClient)
    :ok
  end

  describe "search_coin_by_name/2" do
    test "sends quick replies when coins are found" do
      Application.put_env(:crypto_invest_web, :http_client, fn url ->
        response_body = Jason.encode!(%{"coins" => [%{"id" => "bitcoin", "name" => "Bitcoin"}]})
        {:ok, %HTTPoison.Response{body: response_body}}
      end)

      Application.put_env(:crypto_invest_web, :facebook_client, fn sender_id, body ->
        assert sender_id == "12345"
        assert body == %{
          recipient: %{id: sender_id},
          message: %{
            text: "Please select a coin by choosing an option below:",
            quick_replies: [%{content_type: "text", title: "Bitcoin", payload: "bitcoin"}]
          }
        }
      end)

      CoinSearch.search_coin_by_name("12345", "bitcoin")
    end

    test "sends an error message when no coins are found" do
      Application.put_env(:crypto_invest_web, :http_client, fn _url ->
        response_body = Jason.encode!(%{"coins" => []})
        {:ok, %HTTPoison.Response{body: response_body}}
      end)

      Application.put_env(:crypto_invest_web, :facebook_client, fn sender_id, "No coins found with that name." ->
        assert sender_id == "12345"
      end)

      CoinSearch.search_coin_by_name("12345", "nonexistent")
    end

    test "sends an error message on HTTP error" do
      Application.put_env(:crypto_invest_web, :http_client, fn _url ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      Application.put_env(:crypto_invest_web, :facebook_client, fn sender_id, "Error searching for coin." ->
        assert sender_id == "12345"
      end)

      CoinSearch.search_coin_by_name("12345", "bitcoin")
    end
  end

  describe "search_coin_by_id/2" do
    test "sends price data when coin data is found" do
      start_timestamp = 1_678_500_000
      end_timestamp = 1_678_800_000
      prices = [[start_timestamp * 1_000, 40_000.0]]
      response_body = Jason.encode!(%{"prices" => prices})

      Application.put_env(:crypto_invest_web, :http_client, fn _url ->
        {:ok, %HTTPoison.Response{body: response_body}}
      end)

      Application.put_env(:crypto_invest_web, :facebook_client, fn sender_id, message ->
        assert sender_id == "12345"
        assert message == "Prices for the last 14 days:\n#{DateTime.to_date(DateTime.from_unix!(start_timestamp))}: $40000.0000"
      end)

      CoinSearch.search_coin_by_id("12345", "bitcoin")
    end

    test "sends an error message when no price data is found" do
      Application.put_env(:crypto_invest_web, :http_client, fn _url ->
        response_body = Jason.encode!(%{"prices" => []})
        {:ok, %HTTPoison.Response{body: response_body}}
      end)

      Application.put_env(:crypto_invest_web, :facebook_client, fn sender_id, "No price data found for that coin." ->
        assert sender_id == "12345"
      end)

      CoinSearch.search_coin_by_id("12345", "bitcoin")
    end

    test "sends an error message on HTTP error" do
      Application.put_env(:crypto_invest_web, :http_client, fn _url ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      Application.put_env(:crypto_invest_web, :facebook_client, fn sender_id, "Error fetching coin prices." ->
        assert sender_id == "12345"
      end)

      CoinSearch.search_coin_by_id("12345", "bitcoin")
    end
  end
end
