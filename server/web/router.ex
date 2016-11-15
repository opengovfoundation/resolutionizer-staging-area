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

  pipeline :plain do
    plug :accepts, ["text"]
  end

  scope "/api/v1", Resolutionizer do
    pipe_through :api

    resources "/document", DocumentController, only: [:create]
    get "/templates/last_meeting_date", TemplateController, :last_meeting_date
  end

  scope "/api/v1", Resolutionizer do
    pipe_through :plain

    post "/templates/process_clauses", TemplateController, :process_clauses
  end

  scope "/", Resolutionizer do
    pipe_through :browser # Use the default browser stack

    get "/*path", PageController, :index
  end
end
