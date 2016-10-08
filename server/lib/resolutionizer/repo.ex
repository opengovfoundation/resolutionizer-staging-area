defmodule Resolutionizer.Repo do
  @dialyzer [{:nowarn_function, rollback: 1}]

  @moduledoc false

  use Ecto.Repo, otp_app: :resolutionizer
end
