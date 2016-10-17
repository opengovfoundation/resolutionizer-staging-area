defmodule Resolutionizer.PDF.Template do
  @moduledoc """
  Defines the structure for a valid template configuration and the ability to
  access those valid templates by name.
  """

  @type t :: %__MODULE__{
    file: String.t,
    fields: list,
    options: list
  }

  @type ok_string :: {:ok, String.t}
  @type error_string :: {:error, String.t}

  @typedoc """
  Something that can succeed or fail with a string reasoning.
  """
  @type errorable_result :: ok_string | error_string

  defstruct file: "", fields: [], options: []

  @doc """
  Returns a `%PDF.Template{}` map based on provided template name.
  """
  @spec get(String.t) :: errorable_result
  def get(template_name) do
    try do
      {:ok, String.to_existing_atom("Elixir.Resolutionizer.PDF.Template.#{template_name}")}
    rescue
      _ -> {:error, "Template not found"}
    end
  end

  @doc """
  Checks that all needed fields are provided in a data map for a given template
  """
  @spec check_data(list, map) :: :ok | error_string
  def check_data(fields, data) do
    # Collect missing fields from the data map
    missing_fields = Enum.reduce fields, [], fn(field, missing) ->
      case Map.has_key?(data, Atom.to_string(field)) do
        false -> [ field | missing ]
        true -> missing
      end
    end

    case missing_fields do
      [] -> :ok
      _ -> {:error, "Missing data fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end

end
