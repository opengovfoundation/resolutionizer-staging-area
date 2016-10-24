defmodule Resolutionizer.TemplateController do
  @moduledoc """
  Handles requests regarding Templates.
  """

  use Resolutionizer.Web, :controller

  alias Resolutionizer.Document

  @doc """
  Retrieve the date last used for a meeting date.
  """
  def last_meeting_date(conn, _params) do
    latest_doc = Repo.one(from Document, order_by: [desc: :id], limit: 1)

    date = Map.get(latest_doc.data, "meeting_date")

    json conn, %{date: date}
  end
end
