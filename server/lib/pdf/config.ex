defmodule Resolutionizer.PDF.Config do
  @moduledoc """
  Base configuration struct for the PDF module.
  """

  alias Resolutionizer.PDF

  @type t :: %PDF.Config{
    base_path: String.t,
    template_name: String.t,
    template: PDF.Template.t,
    data: map,
    tmp_dir: String.t
  }

  defstruct(
    # Location of template files for lookup
    base_path: "#{__DIR__}/templates/",

    # Provided name of template
    template_name: "",

    # Actual template object
    template: %PDF.Template{},

    # Data that will be passed to the template for compilation
    data: %{},

    # Temp directory where generated files will be stored
    tmp_dir: ""
  )

  @spec new(list) :: PDF.Config.t
  def new(opts \\ []) do
    __MODULE__
    |> struct([ tmp_dir: "#{System.tmp_dir}/resolutionizer_pdfs" ])
    |> struct(opts)
  end
end
