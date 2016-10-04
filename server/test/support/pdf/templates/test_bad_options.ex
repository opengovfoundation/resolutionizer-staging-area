defmodule Resolutionizer.PDF.Template.TestBadOptions do
  @moduledoc false

  require EEx

  defstruct(
    name: "test_bad_options",
    fields: [:test_field_1, :test_field_2],
    options: [
      "--disable-smart-shrinking",
      "BADOPTION",
      "-T", "25",
      "-B", "25",
      "-L", "25",
      "-R", "25",
    ]
  )

  EEx.function_from_file :def, :render, "#{__DIR__}/test.html.eex", [:assigns]
end
