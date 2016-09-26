defmodule PDF.Template.Resolution do
  defstruct(
    file: "resolution.html.eex",
    fields: [],
    options: [
      "--disable-smart-shrinking",
      "-T", "25",
      "-B", "25",
      "-L", "25",
      "-R", "25",
    ]
  )
end
