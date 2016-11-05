defmodule Resolutionizer.Legistar do
  @moduledoc """
  Interact with Legistar through their WebAPI
  """

  alias Resolutionizer.Document

  @spec create_matter(%Document{}) :: :ok
  def create_matter(document) do
    config = Config.get(:resolutionizer, __MODULE__)

    client = Legistar.Api.client(Config.lookup(config, :client), Config.lookup(config, :key))

    # TODO: add actual error handling to these post processing functions, if
    # initial request fails I think these all just crash

    # get Legistar MatterType id for document type
    matter_type_id =
      Legistar.Api.get("/MatterTypes", query: ["$filter": "MatterTypeName eq 'Resolution'", "$select": "MatterTypeId"])
      |> Map.get(:body)
      |> List.first
      |> Map.get("MatterTypeId")

    # get Legistar MatterStatus id for desired status
    matter_status_id =
      Legistar.Api.get("/MatterStatuses", query: ["$filter": "MatterStatusName eq 'Introduced'", "$select": "MatterStatusId"])
      |> Map.get(:body)
      |> List.first
      |> Map.get("MatterStatusId")

    # get Legistar Body id for City Council
    body_id =
      Legistar.Api.get("/Bodies", query: ["$filter": "BodyName eq 'City Council'", "$select": "BodyId"])
      |> Map.get(:body)
      |> List.first
      |> Map.get("BodyId")

    # TODO: get Legistar Person ids for selected sponsors
    # TODO: get sequential id for new document
  end
end
