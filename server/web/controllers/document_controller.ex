defmodule Resolutionizer.DocumentController do
  @moduledoc """
  Handles requests regarding Documents.
  """

  use Resolutionizer.Web, :controller

  alias Resolutionizer.PDF
  alias Resolutionizer.Document

  @doc """
  Create a new document in the database, generates the resulting PDF and
  uploads it to S3. Response JSON contains PDF and preview JPG URLs.

  POST /api/v1/document
  {
    "document": {
      "title": "Title of the document",
      "template_name": "DocumentType",
      "data": {
        // Data that is passed to template
      }
    }

  }
  """
  def create(conn, %{"document" => document_params}) do
    changeset = Document.changeset(%Document{}, document_params)

    # Save the doc in the Datbase
    case Repo.insert(changeset) do
      {:ok, document} -> generate_document_pdf(conn, document)
      {:error, _} -> Plug.Conn.send_resp(conn, 400, "invalid parameters error")
    end
  end

  # Creates the PDF for the document locally
  defp generate_document_pdf(conn, document) do
    result =
      PDF.start
      |> PDF.template(document.template_name)
      |> PDF.data(document.data)
      |> PDF.generate

    case result do
      {:ok, pdf} -> attach_document_pdf(conn, document, pdf)
      {:error, error} -> Plug.Conn.send_resp(conn, 500, error)
    end
  end

  # Uploads the document to S3
  defp attach_document_pdf(conn, document, pdf) do
    changeset = Document.changeset(document, %{
      file: %{
        content_type: "application/pdf",
        filename: Path.basename(pdf.path),
        path: pdf.path
      }
    })

    # TODO: delete document from tmp in either case
    case Repo.update(changeset) do
      {:ok, new_document} -> render(conn, "show.json", [document: new_document])
      {:error, changeset} ->
        Plug.Conn.send_resp(conn, 500, "file upload error")
    end
  end

end
