defmodule CryptoInvestWeb.WebhookControllerTest do
  use CryptoInvestWeb.ConnCase, async: true
  import CryptoInvestWeb.TestHelpers

  setup do
    # Replace the actual dependencies with fake ones
    Application.put_env(:crypto_invest, :facebook_module, FakeFacebook)
    Application.put_env(:crypto_invest, :coin_search_module, FakeCoinSearch)
    :ok
  end

  describe "GET /api/webhook/verify" do
    test "returns challenge when token is correct", %{conn: conn} do
      conn = get(conn, "/api/webhook", %{"hub.mode" => "subscribe", "hub.verify_token" => "facebook@123", "hub.challenge" => "12345"})
      assert conn.status == 200
      assert conn.resp_body == "12345"
    end

    test "returns forbidden when token is incorrect", %{conn: conn} do
      conn = get(conn, "/api/webhook", %{"hub.mode" => "subscribe", "hub.verify_token" => "wrong_token", "hub.challenge" => "12345"})
      assert conn.status == 403
      assert conn.resp_body == "Forbidden"
    end
  end

  describe "POST /api/webhook" do
    test "handles postback event 'GET_STARTED'", %{conn: conn} do
      payload = %{
        "object" => "page",
        "entry" => [
          %{
            "messaging" => [
              %{
                "sender" => %{"id" => "user123"},
                "postback" => %{"payload" => "GET_STARTED"}
              }
            ]
          }
        ]
      }

      conn = post(conn, "/api/webhook", payload)
      assert conn.status == 200

      # Check if the state was set correctly
      assert :ets.lookup(:user_states, "user123") == [{ "user123", :started_coin_search }]
    end

    test "handles text message event for 'Search by Name'", %{conn: conn} do
      payload = %{
        "object" => "page",
        "entry" => [
          %{
            "messaging" => [
              %{
                "sender" => %{"id" => "user123"},
                "message" => %{"text" => "Search by Name"}
              }
            ]
          }
        ]
      }

      conn = post(conn, "/api/webhook", payload)
      assert conn.status == 200

      # Check if the state was set correctly
      assert :ets.lookup(:user_states, "user123") == [{ "user123", :awaiting_coin_name }]
    end

    test "handles unknown text message", %{conn: conn} do
      payload = %{
        "object" => "page",
        "entry" => [
          %{
            "messaging" => [
              %{
                "sender" => %{"id" => "user123"},
                "message" => %{"text" => "unknown command"}
              }
            ]
          }
        ]
      }

      conn = post(conn, "/api/webhook", payload)
      assert conn.status == 200
    end
  end
end
