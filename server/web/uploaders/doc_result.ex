defmodule Resolutionizer.DocResult do
  @moduledoc """
  Represents a rendered PDF version of a document.
  """

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :preview]

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.pdf .jpg .jpeg) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  def transform(:preview, _) do
    {:convert, fn(input, output) ->
      "-density 150 -strip #{input} +append -quality 100 -background white -flatten png:#{output}"
    end, :png}
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "document_results/#{scope.template_name}/#{scope.id}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/avatars/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: Plug.MIME.path(file.file_name)]
  # end
end
