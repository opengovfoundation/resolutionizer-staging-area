defmodule Resolutionizer.DocumentController do
  @moduledoc """
  Handles requests regarding Documents.
  """

  use Resolutionizer.Web, :controller

  alias Resolutionizer.PDF

  def pdf(conn, %{ "document" => document_params }) do
    result =
      PDF.start
      |> PDF.template(document_params["template_name"])
      |> PDF.data(document_params["data"])
      |> PDF.generate

    case result do
      {:ok, pdf} -> pdf_success(conn, pdf)
      {:error, error} -> pdf_error(conn, error)
    end
  end

  def pdf(conn, _params), do: pdf_bad_request(conn)

  defp pdf_success(conn, pdf) do
    conn
    |> put_resp_header("content-type", "application/pdf")
    |> Plug.Conn.send_file(200, pdf.path)
  end

  defp pdf_bad_request(conn), do: Plug.Conn.send_resp(conn, 400, "Bad request")
  defp pdf_error(conn, error), do: Plug.Conn.send_resp(conn, 500, error)
end
