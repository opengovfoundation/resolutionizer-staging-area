defmodule Resolutionizer.PDF.Template.TestBadTemplate do
  defstruct(
    file: "../../../test/support/pdf/templates/test_bad_template.html.eex",
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
