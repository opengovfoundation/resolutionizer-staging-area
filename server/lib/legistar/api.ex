defmodule Legistar.Api do
  @moduledoc """
  Provides convenience methods for interacting with the Legistar API
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

  @spec get_single_field!(Tesla.Env.client, String.t, String.t, [] | nil) :: String.t
  def get_single_field!(client, url, key, options \\ nil) do
      internal_opts = ["$select": key, "$top": "1"]
      options = Keyword.update(options, :query, internal_opts, fn (existing_opts) ->
        Keyword.merge(existing_opts, internal_opts)
      end)

      client
      |> Legistar.Api.get(url, options)
      |> Map.get(:body)
      |> List.first
      |> Map.get(key)
  end

  @doc """
  The Legistar API returns with plain text strings of the form:

  Matter record has been created. Id: 191169

  Extract the integer from this string.
  """
  @spec parse_created_id!(String.t) :: integer
  def parse_created_id!(str) do
    str
    |> (&Regex.run(~r/.*: (\d+)/, &1, capture: :all_but_first)).()
    |> List.first
    |> String.to_integer
  end
end
