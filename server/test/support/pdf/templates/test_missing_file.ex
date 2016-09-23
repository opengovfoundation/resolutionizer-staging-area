defmodule Resolutionizer.PDF.Template.TestMissingFile do
  defstruct(
    file: "FILE NOT HERE",
    fields: [:test_field_1, :test_field_2],
    options: [
      "--disable-smart-shrinking",
      {"-T", "25"},
      {"-B", "25"},
      {"-L", "25"},
      {"-R", "25"},
    ]
  )
end
