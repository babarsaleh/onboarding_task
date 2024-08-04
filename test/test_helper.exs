ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(CryptoInvest.Repo, :manual)
defmodule CryptoInvestWeb.TestHelpers do
  defmodule MockFacebook do
    def send_user_first_name(_id), do: :ok
    def send_message(_id, _msg), do: :ok
    def send_quick_replies_message(_sender_id, _body), do: :ok
      def send_message(_sender_id, _message) do
    :ok
  end

  def send_quick_replies_message(_sender_id, _body) do
    :ok
  end


  end

  defmodule FakeCoinSearch do
    def search_coin_by_name(_id, _name), do: :ok
    def search_coin_by_id(_id, _id), do: :ok
  end
end
