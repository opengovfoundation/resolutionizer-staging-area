defmodule Resolutionizer.PDF.Template.Resolution do
  @moduledoc false

  require EEx

  defstruct(
    file: "resolution.html.eex",
    fields: [:meeting_date, :sponsors, :clauses],
    options: [
      "--disable-smart-shrinking",
      "-T", "25",
      "-B", "25",
      "-L", "25",
      "-R", "25",
    ]
  )

  EEx.function_from_file :def, :render, "#{__DIR__}/resolution.html.eex", [:assigns]
end
