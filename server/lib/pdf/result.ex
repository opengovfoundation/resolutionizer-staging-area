defmodule Resolutionizer.PDF.Result do
  @moduledoc """
  Returned structure for the result of a PDF generation.
  """

  @type t :: %__MODULE__{
    path: String.t,
    size: integer
  }

  defstruct path: "", size: 0
end
