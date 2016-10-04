defmodule Release.Tasks do
  @moduledoc false

  def migrate do
    {:ok, _} = Application.ensure_all_started(:resolutionizer)

    path = Application.app_dir(:resolutionizer, "priv/repo/migrations")

    Ecto.Migrator.run(Resolutionizer.Repo, path, :up, all: true)
  end
end
