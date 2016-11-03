defmodule Config do
  @moduledoc """
  This module handles fetching values from the config with some additional niceties

  Derived from https://gist.github.com/bitwalker/a4f73b33aea43951fe19b242d06da7b9
  """

  @doc """
  Fetches a value from the config, or from the environment if {:system, "VAR"}
  is provided.

  An optional default value can be provided if desired.

  ## Example

      iex> {test_var, expected_value} = System.get_env |> Enum.take(1) |> List.first
      ...> Application.put_env(:myapp, :test_var, {:system, test_var})
      ...> ^expected_value = #{__MODULE__}.get(:myapp, :test_var)
      ...> :ok
      :ok

      iex> Application.put_env(:myapp, :test_var2, 1)
      ...> 1 = #{__MODULE__}.get(:myapp, :test_var2)
      1

      iex> :default = #{__MODULE__}.get(:myapp, :missing_var, :default)
      :default
  """
  def get(app, key, default \\ nil)

  @spec get(atom, atom, term | nil) :: term
  def get(app, key, default) when is_atom(app) and is_atom(key) do
    process_val(Application.get_env(app, key), default)
  end

  @doc """
  Fetch a nested value.

  ```
  #{__MODULE__}.get(:myapp, [:subsystem, :key])
  ```
  """
  @spec get(atom, nonempty_list(atom), term | nil) :: term
  def get(app, keys = [keys_head | keys_tail], default) when is_atom(app) and is_list(keys) do
    case Application.get_env(app, keys_head) do
      nil ->
        default
      val ->
        lookup(val, keys_tail, default)
    end
  end

  @doc """
  Look up a key in a plain map and process with {:system, "VAR"} support if needed
  """
  @spec lookup(map, atom, term | nil) :: term
  def lookup(may, key, default \\ nil)

  @spec lookup(map, atom, term | nil) :: term
  def lookup(map, key, default) when is_atom(key) do
    lookup(map, [key], default)
  end

  @spec lookup(map, nonempty_list(atom), term | nil) :: term
  def lookup(map, keys, default) when is_list(keys) do
    process_val(get_in(map, keys), default)
  end

  # TODO: get_val? handle_val? parse_val?
  @doc """
  Actually do the lookup for {:system, "ENV_VAR"} format or otherwise return the
  correct value.
  """
  def process_val(val, default \\ nil)

  def process_val({:system, env_var}, default) do
    case System.get_env(env_var) do
      nil -> default
      val -> val
    end
  end

  def process_val({:system, env_var, preconfigured_default}, _default) do
    case System.get_env(env_var) do
      nil -> preconfigured_default
      val -> val
    end
  end

  def process_val(nil, default) do
    default
  end

  def process_val(val, _default) do
    val
  end

  @doc """
  Same as get/3, but returns the result as an integer.
  If the value cannot be converted to an integer, the
  default is returned instead.
  """
  @spec get_integer(atom(), atom(), integer()) :: integer
  def get_integer(app, key, default \\ nil) do
    case get(app, key, nil) do
      nil -> default
      n when is_integer(n) -> n
      n ->
        case Integer.parse(n) do
          {i, _} -> i
          :error -> default
        end
    end
  end
end
