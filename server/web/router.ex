defmodule Resolutionizer.Router do
  @moduledoc false

  use Resolutionizer.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", Resolutionizer do
    pipe_through :api

    post "/document/pdf", DocumentController, :pdf
    get "/document/:id/download/pdf", DocumentController, :download_pdf

    resources "/document", DocumentController
  end

  scope "/", Resolutionizer do
    pipe_through :browser # Use the default browser stack

    get "/*path", PageController, :index
  end
end
