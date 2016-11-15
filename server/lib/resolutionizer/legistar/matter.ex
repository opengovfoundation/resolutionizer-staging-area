defmodule Resolutionizer.Legistar.Matter do
  @moduledoc """
  Document -> Legistar Matter helpers
  """

  alias Resolutionizer.Document

  @doc """
  Create a Legistar Matter record and the related entities based on the given
  Document. Returns the created Legistar Matter Id and the file id.
  """
  @spec create!(Tesla.Env.client, %Document{}) :: {integer, integer}
  def create!(client, document) do
    # TODO: add actual error handling to these post processing functions, if
    # initial request fails I think these all just crash

    # get Legistar MatterType id for document type
    {:ok, matter_type_name} = matter_type_name(document)
    matter_type_id =
      client
      |> Legistar.Api.get_single_field!(
         "/MatterTypes",
         "MatterTypeId",
         query: ["$filter": "MatterTypeName eq '#{matter_type_name}'"]
        )

    # get Legistar MatterStatus id for desired status
    matter_status_id =
      client
      |> Legistar.Api.get_single_field!(
        "/MatterStatuses",
        "MatterStatusId",
        query: ["$filter": "MatterStatusName eq 'Introduced'"]
      )

    # get Legistar Body id for City Council
    body_id =
      client
      |> Legistar.Api.get_single_field!(
        "/Bodies",
        "BodyId",
        query: ["$filter": "BodyName eq 'City Council'"]
      )

    # get Legistar Person ids for selected sponsors
    matter_sponsor_ids = get_legistar_sponsor_ids!(client, document)

    # get file id for new document
    matter_file_id = get_next_matter_file_id!(client, document)

    # submit all the stuff
    meeting_date = Timex.parse!(Map.get(document.data, "meeting_date"), "{ISOdate}")

    matter = %Legistar.Api.Matter{
      MatterFile: matter_file_id,
      MatterTypeId: matter_type_id,
      MatterStatusId: matter_status_id,
      MatterBodyId: body_id,
      MatterIntroDate: meeting_date,
      MatterVersion: "1"
    }

    legistar_matter_id =
      client
      |> Legistar.Api.post("/Matters", matter)
      |> Map.get(:body)
      |> Legistar.Api.parse_created_id!

    post_matter_content(client, legistar_matter_id, matter_file_id, document)

    # make matter sponsors
    Enum.map(matter_sponsor_ids, fn (sponsor_id) ->
      # TODO: do we need to worry about the MatterSponsorSequence field?
      sponsor = %Legistar.Api.MatterSponsor{
        MatterSponsorMatterId: legistar_matter_id,
        MatterSponsorMatterVersion: "1",
        MatterSponsorNameId: sponsor_id
      }

      client
      |> Legistar.Api.post("/Matters/#{legistar_matter_id}/Sponsors", sponsor)
    end)

    {legistar_matter_id, matter_file_id}
  end

  @spec get_legistar_sponsor_ids!(Tesla.Env.client, %Document{}) :: List.t
  def get_legistar_sponsor_ids!(client, document) do
    document.data
    |> Map.get("sponsors")
    |> Enum.map(fn(sponsor) ->
      [last_name, first_name, _ward_or_office] =
        Regex.run(~r/(.*), (.*) \((.*)\)/, sponsor, capture: :all_but_first)

      legistar_person_id =
        Legistar.Api.get_single_field!(
          client,
          "/Persons",
          "PersonId",
          query: ["$filter": "PersonFirstName eq '#{first_name}' and PersonLastName eq '#{last_name}'"]
        )

      legistar_person_id
    end)
  end

  @doc """
  Chicago uses a file naming scheme that includes an indicator of the matter
  type, the year it was introduced and an incrementing number for that matter
  type for the given year. Get the next id in that sequence.
  """
  @spec get_next_matter_file_id!(Tesla.Env.client, %Document{}) :: String.t
  def get_next_matter_file_id!(client, document) do
    # get sequential id for new document
    meeting_date = Timex.parse!(Map.get(document.data, "meeting_date"), "{ISOdate}")
    meeting_year = Timex.beginning_of_year(meeting_date)
    next_year = Timex.shift(meeting_year, years: 1)

    meeting_year_str = Timex.format!(meeting_year, "{YYYY}")
    next_year_str = Timex.format!(next_year, "{YYYY}")

    {:ok, matter_type_name} = matter_type_name(document)

    # TODO: alternatively we could possibly use some filter operations to order
    # by just the last part of the MatterFile name?
    filter = Enum.join([
      "MatterTypeName eq '#{matter_type_name}'",
      "MatterIntroDate ge datetime'#{meeting_year_str}'",
      "MatterIntroDate lt datetime'#{next_year_str}'"
      ], " and ")

    last_matter =
      client
      |> Legistar.Api.get(
        "/Matters",
        query: [
          "$filter": filter,
          "$orderby": "MatterId desc",
          "$top": "1",
          "$select": "MatterFile"
        ])
      |> Map.get(:body)

    seq_id =
      case last_matter do
        [] -> 1
        [head | _tail] ->
          head
            |> Map.get("MatterFile")
            |> (&Regex.run(~r/.*-(\d+)/, &1, capture: :all_but_first)).()
            |> List.first
            |> String.to_integer
            |> Kernel.+(1)
      end

    {:ok, file_name_type} = matter_file_name_type(document)

    "#{file_name_type}#{meeting_year_str}-#{seq_id}"
  end

  @doc """
  Create records for the various contents of the matter, attachments and text versions.
  """
  @spec post_matter_content(Tesla.Env.client, integer, String.t, %Document{}) :: integer
  def post_matter_content(client, legistar_matter_id, matter_file_id, document) do
    matter_pdf_url = Resolutionizer.DocResult.url({document.file, document}, :original, signed: true)
    matter_pdf_content =
      matter_pdf_url
        |> Tesla.get
        |> Map.get(:body)

    matter_attachment = %Legistar.Api.MatterAttachment{
      "MatterAttachmentName": "#{matter_file_id}.pdf",
      "MatterAttachmentFileName": "#{UUID.uuid4()}.pdf",
      "MatterAttachmentBinary": Base.encode64(matter_pdf_content)
    }

    client
    |> Legistar.Api.post("/Matters/#{legistar_matter_id}/Attachments", matter_attachment)
    |> Map.get(:body)
    |> Legistar.Api.parse_created_id!

    # TODO: make a matter text, plain and rtf
  end

  @spec matter_file_name_type(%Document{}) :: {:ok, String.t} | {:error, String.t}
  defp matter_file_name_type(document) do
    case String.downcase(document.template_name) do
      "resolution" -> {:ok, "R"}
      _ -> {:error, "Unknown matter type"}
    end
  end

  @spec matter_type_name(%Document{}) :: {:ok, String.t} | {:error, String.t}
  def matter_type_name(document) do
    case String.downcase(document.template_name) do
      "resolution" -> {:ok, "Resolution"}
      _ -> {:error, "Unknown matter type"}
    end
  end
end
