defmodule Resolutionizer.DocumentController do
  @moduledoc """
  Handles requests regarding Documents.
  """

  use Resolutionizer.Web, :controller

  alias Resolutionizer.PDF

  @doc """
  Creates a new PDF.

  POST /api/v1/document/pdf
  {
    "document": {
      "template_name": "DocumentType",
      "data": {
        // Data that is passed to template
      }
    }
  }
  """
  def pdf(conn), do: Plug.Conn.send_resp(conn, 400, "Bad request")
  def pdf(conn, %{ "document" => document_params }) do
    result =
      PDF.start
      |> PDF.template(document_params["template_name"])
      |> PDF.data(document_params["data"])
      |> PDF.generate

    case result do
      {:ok, pdf} ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Poison.encode!(%{id: Path.basename(pdf.path, ".pdf")}))
      {:error, error} -> Plug.Conn.send_resp(conn, 500, error)
    end
  end

  @doc """
  Download a generated PDF.

  GET /api/v1/document/:id/download/pdf

  TODO: For now, :id is the filename base, in the future it should be a model ID
  """
  def download_pdf(conn), do: Plug.Conn.send_resp(conn, 400, "Bad request")
  def download_pdf(conn, %{ "id" => id }) do
    case PDF.path(id) do
      {:ok, path} ->
        conn
        |> put_resp_header("content-type", "application/pdf")
        |> Plug.Conn.send_file(200, path)
      {:error, msg} -> Plug.Conn.send_resp(conn, 400, msg)
    end
  end
end
