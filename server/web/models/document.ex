defmodule Resolutionizer.Document do
  @moduledoc """
  Represents a document created by a user. Contains a template name and a bundle
  of data for generating a PDF.
  """

  use Resolutionizer.Web, :model

  schema "documents" do
    field :title, :string
    field :template_name, :string
    field :data, :map

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :template_name, :data])
    |> validate_required([:title, :template_name, :data])
  end

end
