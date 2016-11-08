defmodule Legistar.Api.MatterSponsor do
  @moduledoc false

  @derive {Poison.Encoder, only: [:MatterSponsorMatterId, :MatterSponsorMatterVersion, :MatterSponsorNameId]}

  @type t :: %__MODULE__{
    MatterSponsorId: Integer.t,
    MatterSponsorGuid: String.t,
    MatterSponsorLastModifiedUtc: DateTime.t,
    MatterSponsorRowVersion: binary,
    MatterSponsorMatterId: Integer.t,
    MatterSponsorMatterVersion: String.t,
    MatterSponsorNameId: Integer.t,
    MatterSponsorBodyId: Integer.t,
    MatterSponsorName: String.t,
    MatterSponsorSequence: Integer.t,
    MatterSponsorLinkFlag: Integer.t
  }

  @enforce_keys [
    :MatterSponsorMatterId,
    :MatterSponsorMatterVersion,
  ]

  defstruct [
    :MatterSponsorId,
    :MatterSponsorGuid,
    :MatterSponsorLastModifiedUtc,
    :MatterSponsorRowVersion,
    :MatterSponsorMatterId,
    :MatterSponsorMatterVersion,
    :MatterSponsorNameId,
    :MatterSponsorBodyId,
    :MatterSponsorName,
    :MatterSponsorSequence,
    :MatterSponsorLinkFlag
  ]
end
