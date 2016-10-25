defmodule Resolutionizer.PDF.Config do
  @moduledoc """
  Base configuration struct for the PDF module.
  """

  alias Resolutionizer.PDF

  @type t :: %__MODULE__{
    template_name: String.t,
    template: PDF.Template.t,
    data: map,
    tmp_dir: String.t
  }

  defstruct(
    # Provided name of template
    template_name: "",

    # Actual template object
    template: %PDF.Template{},

    # Data that will be passed to the template for compilation
    data: %{},

    # Temp directory where generated files will be stored
    tmp_dir: ""
  )

  @spec new(list) :: t
  def new(opts \\ []) do
    __MODULE__
    |> struct([ tmp_dir: "#{System.tmp_dir}/resolutionizer_pdfs" ])
    |> struct(opts)
  end
end
