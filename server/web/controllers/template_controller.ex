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

  @doc """
  Parse a blob of text into structured clause data
  """
  def process_clauses(conn, _params) do
    # TODO: use actual temp file library
    tmp_file = "#{System.tmp_dir}/test"

    {:ok, body, conn} = Plug.Conn.read_body(conn)

    File.write! tmp_file, body

    clause_data =
      case System.cmd "bulk-clause-import", [tmp_file], stderr_to_stdout: true do
        {json_data, 0} -> {:ok, json_data}
        {err_msg, _} -> {:error, err_msg}
      end

    File.rm tmp_file

    case clause_data do
      {:ok, json_data} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(conn.status || 200, json_data)
      {:error, err_msg} -> send_resp(conn, 400, err_msg)
    end
  end
end
