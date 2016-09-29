defmodule Resolutionizer.PDF.Template.Test do
  @moduledoc false

  defstruct(
    file: "../../../test/support/pdf/templates/test.html.eex",
    fields: [:test_field_1, :test_field_2],
    options: [
      "--disable-smart-shrinking",
      "-T", "25",
      "-B", "25",
      "-L", "25",
      "-R", "25",
    ]
  )
end
