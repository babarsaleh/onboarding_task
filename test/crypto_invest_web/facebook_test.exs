defmodule CryptoInvestWeb.FacebookTest do
  use ExUnit.Case
  import Mock

  alias CryptoInvestWeb.Facebook

  @page_access_token "EABw3Wl4PQagBO2GTwZCDOG1ZAY7Izeukx7YM8prZBXAfJltJkdsxFuZAReJXfn9p8KiwmZCXdo86qgJjpZBGYhTcVigsrAzf11GQcBcLpXyh8wd4kwGRVqYdkEZClBFDt1D7j9ZBx5fPEcoITrAvsZBUNElgCkcZCgr2EZB8kumWrAVZBg2HnRHHF0TImz6VnIhvBfmyZBgZDZD"

  setup do
    :ok
  end

  test "send_message/2 successfully posts a message" do
    with_mock HTTPoison, post: fn _url, _body, _headers ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
    end do
      assert Facebook.send_message("12345", "Hello") == :ok
    end
  end

  test "send_message/2 handles HTTPoison errors" do
    with_mock HTTPoison, post: fn _url, _body, _headers ->
      {:error, %HTTPoison.Error{reason: :timeout}}
    end do
      assert Facebook.send_message("12345", "Hello") == {:error, :timeout}
    end
  end

  test "send_quick_replies_message/2 successfully posts a message" do
    with_mock HTTPoison, post: fn _url, _body, _headers ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
    end do
      assert Facebook.send_quick_replies_message("12345", %{}) == :ok
    end
  end

  test "send_quick_replies_message/2 handles HTTPoison errors" do
    with_mock HTTPoison, post: fn _url, _body, _headers ->
      {:error, %HTTPoison.Error{reason: :timeout}}
    end do
      assert Facebook.send_quick_replies_message("12345", %{}) == {:error, :timeout}
    end
  end

end
