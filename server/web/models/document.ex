defmodule Resolutionizer.Document do
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
