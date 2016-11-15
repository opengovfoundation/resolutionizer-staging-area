defmodule Resolutionizer.Legistar do
  @moduledoc """
  Interact with Legistar through their WebAPI
  """

  def client do
    config = Config.get(:resolutionizer, __MODULE__)

    Legistar.Api.client(
      Config.lookup(config, :client),
      Config.lookup(config, :key)
    )
  end
end
