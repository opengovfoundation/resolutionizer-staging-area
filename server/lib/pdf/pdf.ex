defmodule PDF do
  alias PDF.Config

  @moduledoc """
  A module for generating PDFs using the wkhtmltopdf command line tool.

  Takes incoming data and feeds it to eex HTML templates, which are then run
  through wkhtmltopdf to generate a PDF file.

  ## EXAMPLE API
  
  ```
  PDF.template(template_name)
  |> PDF.data(data)
  |> PDF.settings(settings)
  |> PDF.output(output_file_path)
  ```
  """

  @doc "Start a new PDF, passing in initial configuration."
  def start(%Config{}=opts) do
    opts
  end

  @doc "Set the template used."
  def template(template_name) do
    # find the template file
    # -- checks for existence, 
  end

end
