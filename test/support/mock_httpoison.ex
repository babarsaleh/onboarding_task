defmodule MockHTTPoison do
  def get(_url) do
    # This will be overridden in individual tests
    {:ok, %HTTPoison.Response{body: "default mock response"}}
  end
end
