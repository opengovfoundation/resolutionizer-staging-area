defmodule Legistar.Api do
  @moduledoc """
  Provides convenience methods for constructing requests to the Legistar API
  """

  use Tesla

  plug Tesla.Middleware.JSON

  adapter Tesla.Adapter.Hackney

  @base_url_start "https://webapi.legistar.com/v1"

  def client(client, key) do
    Tesla.build_client [
      {Tesla.Middleware.BaseUrl, @base_url_start <> "/#{client}"},
      {Tesla.Middleware.Query, [key: key]}
    ]
  end
end
