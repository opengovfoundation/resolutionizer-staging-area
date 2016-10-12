defmodule Resolutionizer.PDF.Result do
  @moduledoc """
  Returned structure for the result of a PDF generation.
  """

  alias Resolutionizer.PDF

  @type t :: %PDF.Result{
    path: String.t,
    size: integer
  }

  defstruct path: "", size: 0
end
