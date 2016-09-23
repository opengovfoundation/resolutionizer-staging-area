defmodule Resolutionizer.PDF.Template do
  @moduledoc """
  Defines the structure for a valid template configuration and the ability to
  access those valid templates by name.
  """

  defstruct file: "", fields: [], options: []

  @doc """
  Returns a `%PDF.Template{}` map based on provided template name.
  """
  def get(template_name) do
    try do
      {:ok, struct(String.to_existing_atom("Elixir.Resolutionizer.PDF.Template.#{template_name}"))}
    rescue
      _ -> {:error, "Template not found"}
    end
  end

  @doc """
  Checks that all needed fields are provided in a data map for a given template
  """
  def check_data(fields, data) do
    # Collect missing fields from the data map
    missing_fields = Enum.reduce fields, [], fn(field, missing) ->
      case Keyword.has_key?(data, field) do
        false -> [ field | missing ]
        true -> missing
      end
    end

    case missing_fields do
      [] -> :ok
      _ -> {:error, "Missing data fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  @doc """
  Checks if the template file exists with base path and file name combo
  """
  def check_template_file(base_path, file) do
    case File.exists?("#{base_path}/#{file}") do
      true -> :ok
      false -> {:error, "Template file missing"}
    end
  end

end
