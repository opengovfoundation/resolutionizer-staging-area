defmodule Resolutionizer.PDFTest do
  @moduledoc false

  use ExUnit.Case

  alias Resolutionizer.PDF

  @output_dir "#{System.tmp_dir}/resolutionizer_pdfs/test"

  doctest PDF

  # Clear out the test output dir each time
  setup do
    on_exit fn -> File.rm_rf @output_dir end
  end

  # PDF.start/0

  test """
  start returns Config struct
  """ do
    assert PDF.start == PDF.Config.new
  end

  test """
  start returns default config struct
  """ do
    default_config = PDF.start
    assert default_config.tmp_dir
    assert default_config.template == %PDF.Template{}
    assert default_config.data == %{}
  end

  # PDF.start/1

  test """
  passing in initial config sets those options on the config map
  """ do
    config = PDF.start %{ tmp_dir: "/new/path" }
    assert config.tmp_dir == "/new/path"
  end

  # PDF.template/2

  test """
  setting template name with PDF.template/2 sets template name config
  """ do
    config = PDF.start |> PDF.template("Test")
    assert config.template_name == "Test"
  end

  test """
  disallow empty template name
  """ do
    assert_raise FunctionClauseError, fn ->
      PDF.start |> PDF.template("")
    end
  end

  # PDF.data/2

  test """
  setting data to config object works
  """ do
    data = %{ "test_field_1" => "dat", "test_field_2" => "moar data" }

    config =
      %{ tmp_dir: @output_dir }
      |> PDF.start
      |> PDF.template("Test")
      |> PDF.data(data)

    assert config.data == data
  end

  # PDF.generate/1

  test """
  catches error: template not found
  """ do
    result =
      %{ tmp_dir: @output_dir }
      |> PDF.start
      |> PDF.template("NotARealTemplate")
      |> PDF.data(%{})
      |> PDF.generate

    assert result == {:error, "Template not found"}
  end

  test """
  catches error: missing data fields
  """ do
    result =
      %{ tmp_dir: @output_dir }
      |> PDF.start
      |> PDF.template("Test")
      |> PDF.data(%{ "test_field_1" => "data" })
      |> PDF.generate

    assert result == {:error, "Missing data fields: test_field_2"}
  end

  test """
  catches error: wkhtmltopdf error
  """ do
    result =
      %{ tmp_dir: @output_dir }
      |> PDF.start
      |> PDF.template("TestBadOptions")
      |> PDF.data(%{ "test_field_1" => "data", "test_field_2" => "moar data" })
      |> PDF.generate

    {status, error} = result

    assert status == :error
    assert String.match? error, ~r/wkhtmltopdf/
  end

  test """
  returns %PDF.Result{} with valid file size and path
  """ do
    result =
      %{ tmp_dir: @output_dir }
      |> PDF.start
      |> PDF.template("Test")
      |> PDF.data(%{ "test_field_1" => "data", "test_field_2" => "moar data" })
      |> PDF.generate

    {status, %{ path: path, size: size }} = result

    %{ size: real_size } = File.stat! path

    assert status == :ok
    assert String.match? path, ~r/resolutionizer_pdfs\/test\/test_(\d+)\.pdf/
    assert real_size == size
  end

  # PDF.path/1

  test "it returns the full path to a PDF if it exists" do
    {:ok, pdf} = make_pdf
    {:ok, full_path} = PDF.path(Path.basename(pdf.path, ".pdf"), @output_dir)
    assert full_path == pdf.path
  end

  test "it returns an error if the PDF does not exist" do
    {status, _} = PDF.path("notarealfilelolololol", @output_dir)
    assert status == :error
  end

  defp make_pdf do
    %{ tmp_dir: @output_dir }
    |> PDF.start
    |> PDF.template("Test")
    |> PDF.data(%{ "test_field_1" => "data", "test_field_2" => "moar data" })
    |> PDF.generate
  end

end
