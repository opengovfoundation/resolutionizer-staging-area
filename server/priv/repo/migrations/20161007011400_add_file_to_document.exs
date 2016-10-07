defmodule Resolutionizer.Repo.Migrations.AddFileToDocument do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add :file, :string
    end
  end
end
