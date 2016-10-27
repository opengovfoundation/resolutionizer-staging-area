defmodule Resolutionizer.PDF.Template.Resolution do
  @moduledoc false

  require EEx

  defstruct(
    name: "resolution",
    fields: [:meeting_date, :sponsors, :clauses],
    options: [
      "--disable-smart-shrinking",
      "--no-background",
      "-T", "25",
      "-B", "25",
      "-L", "25",
      "-R", "25",
      "-s", "Letter",
    ]
  )

  EEx.function_from_file :def, :render, "#{__DIR__}/resolution/parchment.html.eex", [:assigns]
end
