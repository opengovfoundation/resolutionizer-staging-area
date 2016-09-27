defmodule Resolutionizer.PDF.Template.Resolution do
  @moduledoc false

  defstruct(
    file: "resolution.html.eex",
    fields: [:sponsors, :content],
    options: [
      "--disable-smart-shrinking",
      "-T", "25",
      "-B", "25",
      "-L", "25",
      "-R", "25",
    ]
  )
end
