defmodule Resolutionizer.PDF do
  alias Resolutionizer.PDF.Config
  alias Resolutionizer.PDF.Template
  alias Resolutionizer.PDF.Result

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

  `data` is expected to be a Map
  `template_name` is expcted to be a String

  Error handling will occur in PDF.generate/1
  """

  @type ok_string :: {:ok, String.t}
  @type error_string :: {:error, String.t}
  @type error_atom :: {:error, atom}

  @typedoc """
  Something that can succeed or fail with a string reasoning.
  """
  @type errorable_result :: ok_string | error_string | error_atom

  @doc "Start a new PDF, passing in initial configuration."
  @spec start(list) :: Config.t
  def start(opts \\ []), do: Config.new(opts)

  @doc """
  Set the template used. Templates defined in `./templates/`.
  """
  @spec template(Config.t, String.t) :: Config.t
  def template(%Config{} = config, template_name) when template_name != "" do
    struct(config, [template_name: template_name])
  end

  @doc """
  Set the data to be used in the `.html.eex` template
  """
  @spec data(Config.t, map) :: Config.t
  def data(%Config{} = config, data) do
    struct(config, [data: data])
  end

  @doc """
  Take a `%PDF.Config{}` and generates the resulting `%PDF.Result{}`

  Returns a result object of either `{:error, reason}` or `{:ok, %PDF.Result{}}`
  """
  @spec generate(Config.t) :: {:ok, Result.t} | error_string
  def generate(%Config{} = config) do
    with {:ok, loaded_config} <- load_template(config),
         :ok <- check_template(loaded_config),
         {:ok, html_path} <- compile_html(loaded_config),
         {:ok, pdf_result} <- generate_pdf(loaded_config, html_path),
    do: {:ok, pdf_result}
  end

  @spec load_template(Config.t) :: errorable_result
  defp load_template(config) do
    case Template.get(config.template_name) do
      {:ok, template} -> {:ok, struct(config, [template: template])}
      error -> error
    end
  end

  @spec check_template(Config.t) :: :ok | error_string
  defp check_template(config) do
    with :ok <- Template.check_data(struct(config.template).fields, config.data),
    do: :ok
  end

  @spec compile_html(Config.t) :: errorable_result
  defp compile_html(config) do
    file_base = struct(config.template).name

    output_path = "#{config.tmp_dir}/#{file_base}_#{System.system_time}.html"

    try do
      result = config.template.render(data_map_to_list(config.data))
      write_html_result(config, result, output_path)
    rescue
      e in EEx.SyntaxError -> {:error, "EEx.SyntaxError: #{e.message}"}
      _ -> {:error, "Unknown error in HTML rendering"}
    end
  end

  @spec write_html_result(Config.t, String.t, String.t) :: errorable_result
  defp write_html_result(config, result, output_path) do
    with :ok <- File.mkdir_p(config.tmp_dir),
         :ok <- File.write(output_path, result),
    do: {:ok, output_path}
  end

  # Takes a map of string key'd data and converts it into an atom keyword list
  @spec data_map_to_list(map) :: list
  defp data_map_to_list(data_map) do
    for {key, val} <- data_map, into: [], do: { String.to_atom(key), val }
  end

  @spec generate_pdf(Config.t, String.t) :: {:ok, Result.t} | error_string
  defp generate_pdf(config, html_path) do
    pdf_path = String.replace(html_path, ".html", ".pdf")
    options = Enum.concat(struct(config.template).options, ["-q", html_path, pdf_path])

    case System.cmd "wkhtmltopdf", options, stderr_to_stdout: true do
      {_, 0} -> {:ok, %Result{ path: pdf_path, size: get_file_size(pdf_path) }}
      {_, status} -> {:error, "wkhtmltopdf error, Status: #{status}"}
    end
  end

  @spec get_file_size(String.t) :: integer
  defp get_file_size(path) do
    %{size: size} = File.stat!(path)
    size
  end

  @doc """
  Returns the full file path to an existing PDF.
  """
  @spec path(String.t) :: {atom, String.t}
  def path(base), do: path_check("#{System.tmp_dir}/resolutionizer_pdfs/#{base}.pdf")

  @spec path(String.t, String.t) :: {atom, String.t}
  def path(base, dir) do
    path_check("#{dir}/#{base}.pdf")
  end

  @spec path_check(String.t) :: errorable_result
  defp path_check(full_path) do
    case File.exists?(full_path) do
      true -> {:ok, full_path}
      false -> {:error, "File not found"}
    end
  end

end
