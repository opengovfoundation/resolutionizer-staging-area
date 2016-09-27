defmodule Resolutionizer.PDF.Config do
  @moduledoc """
  Base configuration struct for the PDF module.
  """

  alias Resolutionizer.PDF

  defstruct(
    # Location of template files for lookup
    base_path: "#{__DIR__}/templates/",

    # Provided name of template
    template_name: "",

    # Actual template object
    template: %PDF.Template{},

    # Data that will be passed to the template for compilation
    data: [],

    # Temp directory where generated files will be stored
    tmp_dir: "#{System.tmp_dir}/resolutionizer_pdfs"
  )
end
