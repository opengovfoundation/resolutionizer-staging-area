defmodule Resolutionizer.PageController do
  use Resolutionizer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
