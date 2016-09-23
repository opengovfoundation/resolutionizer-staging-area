defmodule Resolutionizer.PDF do
  alias Resolutionizer.PDF.Config
  alias Resolutionizer.PDF.Template
  #alias Resolutionizer.PDF.Result

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

  def data(%Config{}=config, data) do
    struct(config, [data: data])
  end

  @doc """
  Take a `%PDF.Config{}` and generates the resulting `%PDF.Result{}`
  
  Returns a result object of either `{:error, reason}` or `{:ok, %PDF.Result{}}`
  """

  def generate(%Config{}=config) do
    with {:ok, loaded_config} <- load_template(config),
         :ok <- check_template(loaded_config),
         {:ok, html_path} <- compile_html(loaded_config),
         #{:ok, pdf_result} <- generate_pdf(loaded_config, html_path),
    #do: {:ok, pdf_result}
    do: :ok
  end

  defp load_template(config) do
    case Template.get(config.template_name) do
      {:ok, template} -> {:ok, struct(config, [template: template])}
      error -> error
    end
  end

  defp check_template(config) do
    with :ok <- Template.check_template_file(config.base_path, config.template.file),
         :ok <- Template.check_data(config.template.fields, config.data),
    do: :ok
  end

  defp compile_html(config) do
    template_file = "#{config.base_path}/#{config.template.file}"
    file_base = String.replace(config.template.file, ".html.eex", "")
    output_file = "#{config.tmp_dir}/#{file_base}_#{System.system_time}.pdf"

    try do
      File.mkdir_p! config.tmp_dir
      result = EEx.eval_file template_file, config.data
      File.write! output_file, result
      output_file
    rescue
      e in EEx.SyntaxError -> {:error, "EEx.SyntaxError: #{e.message}"}
    end
  end

  #defp generate_pdf(html_path, wk_opts) do
  #  # TODO: take wk_opts and html_path and run wkhtmltopdf, return a
  #  # %Result{} (file, size)
  #end

end
