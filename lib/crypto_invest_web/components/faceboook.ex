defmodule CryptoInvestWeb.Facebook do
  alias HTTPoison
  alias Jason
  require Logger

  @page_access_token "access token"
  @url "https://graph.facebook.com/v12.0/me/messages?access_token=#{@page_access_token}"

  def send_message(recipient_id, text) do
    body = %{
      recipient: %{id: recipient_id},
      message: %{text: text}
    }

    case HTTPoison.post(
      "#{@url}",
      Jason.encode!(body),
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, _response} ->
        :ok

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to send message: #{reason}")
        {:error, reason}
    end
  end

  def send_quick_replies_message(sender_id, message) do
    case HTTPoison.post(
      "#{@url}",
      Jason.encode!(message),
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, _response} ->
        :ok

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to send quick replies message: #{reason}")
        {:error, reason}
    end
  end

  def send_user_first_name(sender_id) do
    url = "https://graph.facebook.com/v12.0/#{sender_id}?fields=first_name&access_token=#{@page_access_token}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"first_name" => first_name}} ->
            send_personalized_initial_options(sender_id, first_name)
          
          {:ok, %{"error" => error}} ->
            Logger.error("Error parsing user profile: #{inspect(error)}")
            send_personalized_initial_options(sender_id, "there")
          
          {:error, reason} ->
            Logger.error("Error decoding JSON response: #{reason}")
            send_personalized_initial_options(sender_id, "there")
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Error fetching user profile: #{reason}")
        send_personalized_initial_options(sender_id, "there")
    end
  end

  defp send_personalized_initial_options(sender_id, first_name) do
    body = %{
      recipient: %{id: sender_id},
      message: %{
        text: "Hi Babar! Welcome to our CryptoInvest app. How can I assist you today?",
        quick_replies: [
          %{
            content_type: "text",
            title: "Search by Name",
            payload: "SEARCH_BY_NAME"
          },
          %{
            content_type: "text",
            title: "Search by Coin",
            payload: "SEARCH_BY_COIN"
          }
        ]
      }
    }

    send_quick_replies_message(sender_id, body)
  end
end
