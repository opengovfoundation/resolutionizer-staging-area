defmodule Resolutionizer.DocumentControllerTest do
  @moduledoc false

  use Resolutionizer.ConnCase

  alias Resolutionizer.Document

  @valid_attrs %{
    title: "Doc Title",
    template_name: "Test",
    data: %{
      "test_field_1" => "Hello",
      "test_field_2" => "World"
    }
  }
  
  test "successfully creates a new document", %{conn: conn} do
    conn = post(conn, document_path(conn, :create), document: @valid_attrs)
    document = Repo.get_by(Document, @valid_attrs)

    assert json_response(conn, 200) == %{
     "document" => %{
       "id" => document.id,
       "title" => document.title,
       "template_name" => document.template_name,
       "data" => document.data
     }
    }
  end

end
