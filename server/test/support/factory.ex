defmodule Resolutionizer.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Resolutionizer.Repo

  alias Resolutionizer.Document

  def document_factory do
    %Document{
      title: "Check out this awesome resolution",
      template_name: "Test",
      data: %{ "test_field_1": "data", "test_field_2": "moar data" }
    }
  end
end
