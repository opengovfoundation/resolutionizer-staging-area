defmodule Resolutionizer.PageController do
  @moduledoc """
  Exists only to serve up our static index.html page to any non-API request
  """

  use Resolutionizer.Web, :controller

  def index(conn, _params) do
    conn
      |> put_resp_header("content-type", "text/html; charset=utf-8")
      |> Plug.Conn.send_file(200, "priv/static/index.html")
  end
end
