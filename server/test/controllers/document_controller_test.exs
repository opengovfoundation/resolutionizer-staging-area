defmodule Resolutionizer.DocumentControllerTest do
  @moduledoc false

  use Resolutionizer.ConnCase

  import Mock

  alias Resolutionizer.Document
  alias Resolutionizer.DocResult

  @valid_attrs %{
    title: "Doc Title",
    template_name: "Test",
    data: %{
      "test_field_1" => "Hello",
      "test_field_2" => "World"
    }
  }

  test_with_mock "successfully creates a new document", %{conn: conn},
  DocResult, [], [
    store: fn(_) -> {:ok, nil}  end,
    urls: fn(file_and_scope, opts) -> doc_result_urls(file_and_scope, opts) end
  ] do
    conn = post(conn, document_path(conn, :create), document: @valid_attrs)
    document = Repo.get_by(Document, @valid_attrs)

    assert json_response(conn, 200) == json_response_for_document(document)
  end

  defp json_response_for_document(document) do
    # Convert the DocResult urls for this doc into string-keyed map
    urls = for {key, val} <-
      DocResult.urls({document.file, document}, nil),
      into: %{},
      do: {Atom.to_string(key), val}

    %{ "document" => %{
       "id" => document.id,
       "title" => document.title,
       "template_name" => document.template_name,
       "data" => document.data,
       "urls" => urls
     }
    }
  end

  def doc_result_urls({file, document}, _opts) do
    %{
      original: "#{document.id}/#{file.file_name}.pdf",
      preview: "#{document.id}/#{file.file_name}.png"
    }
  end

end
