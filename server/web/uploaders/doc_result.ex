defmodule Resolutionizer.DocResult do
  @moduledoc """
  Represents a rendered PDF version of a document.
  """

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :preview]

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.pdf) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  def transform(:preview, {_file, scope}) do
    template = String.downcase(scope.template_name)
    {"./lib/pdf/templates/#{template}/#{template}.preview.sh", fn(input, output) ->
      [input, output]
    end, :jpg}
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "document_results/#{scope.template_name}/#{scope.id}"
  end
end
