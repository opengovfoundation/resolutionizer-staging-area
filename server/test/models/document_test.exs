defmodule Resolutionizer.DocumentTest do
  use Resolutionizer.ModelCase

  alias Resolutionizer.Document
  alias Resolutionizer.DocResult

  @valid_attrs %{
    data: %{ "foo" => "bar" },
    template_name: "some content",
    title: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Document.changeset(%Document{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Document.changeset(%Document{}, @invalid_attrs)
    refute changeset.valid?
  end

end
