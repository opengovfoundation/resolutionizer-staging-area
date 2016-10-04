defmodule Resolutionizer.DocumentView do
  @moduledoc false

  alias Resolutionizer.DocResult

  def render("show.json", %{document: document}) do
     document_json(document)
  end

  defp document_json(document) do
    %{
      document: %{
        id: document.id,
        title: document.title,
        template_name: document.template_name,
        data: document.data,
        urls: DocResult.urls({"result", document}, signed: true)
      }
    }
  end
end
