defmodule Resolutionizer.PDF do
  alias Resolutionizer.PDF.Config
  #alias Resolutionizer.PDF.Result
  #alias Resolutionizer.PDF.Template

  @moduledoc """
  A module for generating PDFs using the wkhtmltopdf command line tool.

  Takes incoming data and feeds it to eex HTML templates, which are then run
  through wkhtmltopdf to generate a PDF file.

  ## EXAMPLE API
  
  ```
  PDF.start
  |> PDF.template(template_name)
  |> PDF.data(data)
  |> PDF.generate
  ```

  Error handling will occur in PDF.generate/1
  """

  @doc "Start a new PDF, passing in initial configuration."
  def start(opts \\ []), do: struct(Config, opts)

  @doc """
  Set the template used. Templates defined in `./templates/`.
  """

  def template(%Config{}=config, template_name) when template_name != "" do
    struct(config, [template_name: template_name])
  end

  @doc """
  Set the data to be used in the `.html.eex` template
  """

  def data(%Config{}=config, %{}=data) do
    struct(config, [data: data])
  end

  #@doc """
  #Take a `%PDF.Config{}` and generates the resulting `%PDF.Result{}`
  
  #Returns a result object of either `{:error, reason}` or `{:ok, %PDF.Result{}}`
  #"""

  #def generate(%Config{}=config) do
  #  with {:ok, loaded_config} <- load_template(config),
  #       {:ok, html_path} <- compile_html(loaded_config),
  #       {:ok, pdf_result} <- generate_pdf(loaded_config, html_path),
  #  do: {:ok, pdf_result}
  #end

  #defp load_template(config) do
  #  case Template.get(config.template_name) do
  #    {:ok, template} -> struct(config, [template: template])
  #    error -> error
  #  end
  #end

  #defp compile_html(config) do
  #  template_file = "#{config.base_path}/#{config.template.file}"
  #  compiled_html = EEx.eval_file template_file, config.data
  #  # TODO: write compiled html to a file in `System.tmp_dir`
  #  # TODO: return path to compiled html file
  #end

  #defp generate_pdf(html_path, wk_opts) do
  #  # TODO: take wk_opts and html_path and run wkhtmltopdf, return a
  #  # %Result{} (file, size)
  #end

end
