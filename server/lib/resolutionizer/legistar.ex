defmodule Resolutionizer.Legistar do
  @moduledoc """
  Interact with Legistar through their WebAPI
  """

  alias Resolutionizer.Document

  @spec create_matter!(%Document{}) :: {:ok, integer, integer}
  def create_matter!(document) do
    config = Config.get(:resolutionizer, __MODULE__)

    client = Legistar.Api.client(Config.lookup(config, :client), Config.lookup(config, :key))

    # TODO: add actual error handling to these post processing functions, if
    # initial request fails I think these all just crash

    # get Legistar MatterType id for document type
    matter_type_id =
      get_single_field!(client, "/MatterTypes", "MatterTypeId", query: ["$filter": "MatterTypeName eq 'Resolution'"])

    # get Legistar MatterStatus id for desired status
    matter_status_id =
      get_single_field!(
        client,
        "/MatterStatuses",
        "MatterStatusId",
        query: ["$filter": "MatterStatusName eq 'Introduced'"]
      )

    # get Legistar Body id for City Council
    body_id =
      get_single_field!(client, "/Bodies", "BodyId", query: ["$filter": "BodyName eq 'City Council'"])

    # get Legistar Person ids for selected sponsors
    matter_sponsor_ids =
      document.data
      |> Map.get("sponsors")
      |> Enum.map(fn(sponsor) ->
        [last_name, first_name, _ward_or_office] =
          Regex.run(~r/(.*), (.*) \((.*)\)/, sponsor, capture: :all_but_first)

        legistar_person_id =
          get_single_field!(
            client,
            "/Persons",
            "PersonId",
            query: ["$filter": "PersonFirstName eq '#{first_name}' and PersonLastName eq '#{last_name}'"]
          )

        legistar_person_id
      end)

    # get sequential id for new document
    meeting_date = Timex.parse!(Map.get(document.data, "meeting_date"), "{ISOdate}")
    meeting_year = Timex.beginning_of_year(meeting_date)
    next_year = Timex.shift(meeting_year, years: 1)

    meeting_year_str = Timex.format!(meeting_year, "{YYYY}")
    next_year_str = Timex.format!(next_year, "{YYYY}")

    # TODO: alternatively we could possibly use some filter operations to order
    # by just the last part of the MatterFile name?
    filter = Enum.join([
      "MatterTypeName eq 'Resolution'",
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

      matter_file_id = "R#{meeting_year_str}-#{seq_id}"

      # submit all the stuff

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
        |> parse_created_id!

      # make a matter attachment
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

      _matter_attachment_id =
        client
        |> Legistar.Api.post("/Matters/#{legistar_matter_id}/Attachments", matter_attachment)
        |> Map.get(:body)
        |> parse_created_id!

      # TODO: make a matter text, plain and rtf?

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

      {:ok, legistar_matter_id, matter_file_id}
  end

  @doc """
  The Legistar API returns with plain text strings of the form:

  Matter record has been created. Id: 191169

  Extract the integer from this string.
  """
  @spec parse_created_id!(String.t) :: integer
  def parse_created_id!(str) do
    str
      |> (&Regex.run(~r/.*: (\d+)/, &1, capture: :all_but_first)).()
      |> List.first
      |> String.to_integer
  end

  @spec get_single_field!(Tesla.Env.client, String.t, String.t, [] | nil) :: String.t
  def get_single_field!(client, url, key, options \\ nil) do
      internal_opts = ["$select": key, "$top": "1"]
      options = Keyword.update(options, :query, internal_opts, fn (existing_opts) ->
        Keyword.merge(existing_opts, internal_opts)
      end)

      client
      |> Legistar.Api.get(url, options)
      |> Map.get(:body)
      |> List.first
      |> Map.get(key)
  end
end
