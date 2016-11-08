defmodule Legistar.Api.MatterText do
  @moduledoc false

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{
    MatterTextId: Integer.t,
    MatterTextGuid: String.t,
    MatterTextLastModifiedUtc: DateTime.t,
    MatterTextRowVersion: binary,
    MatterTextMatterId: Integer.t,
    MatterTextVersion: String.t,
    MatterTextPlain: String.t,
    MatterTextRtf: String.t
  }

  @enforce_keys [
    :MatterTextMatterId
  ]

  defstruct [
    :MatterTextId,
    :MatterTextGuid,
    :MatterTextLastModifiedUtc,
    :MatterTextRowVersion,
    :MatterTextMatterId,
    :MatterTextVersion,
    :MatterTextPlain,
    :MatterTextRtf
  ]
end
