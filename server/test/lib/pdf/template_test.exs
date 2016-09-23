defmodule Resolutionizer.PDF.TemplateTest do
  @moduledoc false

  import Resolutionizer.PDF.Template.Test

  alias Resolutionizer.PDF

  use ExUnit.Case

  # PDF.Template.get/1

  test "returns specified template config map if valid" do
    {:ok, result} = PDF.Template.get("Test")
    assert result == %PDF.Template.Test{}
  end

  test "returns error if template not found" do
    {:error, error} = PDF.Template.get("not a thing")
    assert error == "Template not found"
  end

  # PDF.Template.check_data/2

  test "returns success result if data map has all required fields" do
    assert PDF.Template.check_data([:test_field_1, :test_field_2], [
      test_field_1: "data",
      test_field_2: "moar data"
    ]) == :ok
  end

  test """
  returns error and missing field list if data map does NOT have all fields
  """ do
    assert PDF.Template.check_data([:test_field_1, :test_field_2], [
      test_field_1: "data"
    ]) == {:error, "Missing data fields: test_field_2"}
  end

  # PDF.Template.check_template_file/2

  test """
  returns ok if template file exists
  """ do
    config = %PDF.Config{}
    template = %PDF.Template.Test{}

    assert PDF.Template.check_template_file(config.base_path, template.file) == :ok
  end

  test """
  returns {:error, "Template file missing"} if template file does not exist
  """ do
    config = %PDF.Config{}
    template = %PDF.Template.TestMissingFile{}

    assert PDF.Template.check_template_file(config.base_path, template.file) == {:error, "Template file missing"}
  end
end
