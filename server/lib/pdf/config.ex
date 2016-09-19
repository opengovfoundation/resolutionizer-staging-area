defmodule PDF.Config do
  defstruct(
    # Location of template files for lookup
    base_path: "#{__DIR__}/templates/",

    # Provided name of template file, without the `.html.eex`
    template_name: "",

    # Data that will be passed to the template for compilation
    data: %{},

    # Location of HTML result file to be passed to wkhtmltopdf
    html_result: "",

    # Location of resulting PDF file from wkhtmltopdf
    pdf_result: ""
  )
end
