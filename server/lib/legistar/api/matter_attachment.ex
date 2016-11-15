defmodule Legistar.Api.MatterAttachment do
  @moduledoc false

  # TODO: when creating a new attachment, it complains if any of the fields null
  @derive {Poison.Encoder, only: [:MatterAttachmentName, :MatterAttachmentFileName, :MatterAttachmentBinary]}

  @type t :: %__MODULE__{
    MatterAttachmentId: Integer.t,
    MatterAttachmentGuid: String.t,
    MatterAttachmentLastModifiedUtc: DateTime.t,
    MatterAttachmentRowVersion: binary,
    MatterAttachmentName: String.t,
    MatterAttachmentHyperlink: String.t,
    MatterAttachmentFileName: String.t,
    MatterAttachmentBinary: binary,
    MatterAttachmentIsSupportingDocument: boolean,
    MatterAttachmentShowOnInternetPage: boolean,
    MatterAttachmentIsMinuteOrder: boolean,
    MatterAttachmentIsBoardLetter: boolean
  }

  @enforce_keys [
    :MatterAttachmentName
  ]

  defstruct [
    :MatterAttachmentId,
    :MatterAttachmentGuid,
    :MatterAttachmentLastModifiedUtc,
    :MatterAttachmentRowVersion,
    :MatterAttachmentName,
    :MatterAttachmentHyperlink,
    :MatterAttachmentFileName,
    :MatterAttachmentBinary,
    :MatterAttachmentIsSupportingDocument,
    :MatterAttachmentShowOnInternetPage,
    :MatterAttachmentIsMinuteOrder,
    :MatterAttachmentIsBoardLetter
  ]
end
