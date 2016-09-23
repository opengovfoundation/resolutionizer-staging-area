defmodule Resolutionizer.PDFTest do
  @moduledoc false

  use ExUnit.Case

  alias Resolutionizer.PDF

  import Resolutionizer.PDF.Config
  import Resolutionizer.PDF.Template.Test
  import Resolutionizer.PDF.Template.TestMissingFile

  doctest PDF

  # PDF.start/0

  test """
  start returns Config struct
  """ do
    assert PDF.start == %PDF.Config{}
  end

  test """
  start returns default config struct
  """ do
    default_config = PDF.start
    assert default_config.base_path
    assert default_config.template == %PDF.Template{}
    assert default_config.data == []
  end

  # PDF.start/1

  test """
  passing in initial config sets those options on the config map
  """ do
    config = PDF.start %{ base_path: "/new/path" }
    assert config.base_path == "/new/path"
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
    data = [ test_field_1: "dat", test_field_2: "moar data" ]

    config = PDF.start
    |> PDF.template("Test")
    |> PDF.data(data)

    assert config.data == data
  end

  # PDF.generate/1

  test """
  catches error: template not found
  """ do
    result = PDF.start
    |> PDF.template("NotARealTemplate")
    |> PDF.data([])
    |> PDF.generate

    assert result == {:error, "Template not found"}
  end

  test """
  catches error: template file missing
  """ do
    result = PDF.start
    |> PDF.template("TestMissingFile")
    |> PDF.data([])
    |> PDF.generate

    assert result == {:error, "Template file missing"}
  end

  test """
  catches error: missing data fields
  """ do
    result = PDF.start
    |> PDF.template("Test")
    |> PDF.data([test_field_1: "data"])
    |> PDF.generate

    assert result == {:error, "Missing data fields: test_field_2"}
  end

  test """
  catches error: EEx.SyntaxError
  """ do
    result = PDF.start
    |> PDF.template("TestBadTemplate")
    |> PDF.data([test_field_1: "data", test_field_2: "moar data"])
    |> PDF.generate

    assert result == {:error, "EEx.SyntaxError: missing token '%>'"}
  end

  #test """
  #catches error: wkhtmltopdf error
  #"""

  #test """
  #returns %PDF.Result{} with valid file size and path
  #"""

end
