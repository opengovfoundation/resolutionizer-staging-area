defmodule Resolutionizer.Repo.Migrations.CreateDocument do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :title, :string
      add :template_name, :string
      add :data, :map

      timestamps()
    end

  end
end
