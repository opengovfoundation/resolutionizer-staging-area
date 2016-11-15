defmodule ConfigTest do
  @moduledoc false

  use ExUnit.Case

  setup do
    on_exit fn ->
        System.delete_env("TEST_VAR")
        Application.delete_env(:test, :test_var)
      end
  end

  test """
  Handles normal values
  """ do
    Application.put_env(:test, :test_var, "simple value")

    assert Config.get(:test, :test_var) == "simple value"
  end

  test """
  Handles {:system, "VAR"} when "VAR" exists
  """ do
    Application.put_env(:test, :test_var, {:system, "TEST_VAR"})
    System.put_env("TEST_VAR", "I exist")

    assert Config.get(:test, :test_var) == "I exist"
  end

  test """
  Handles {:system, "VAR", default} when "VAR" exists
  """ do
    Application.put_env(:test, :test_var, {:system, "TEST_VAR"})
    System.put_env("TEST_VAR", "I exist")

    assert Config.get(:test, :test_var, "not used") == "I exist"
  end

  test """
  Handles {:system, "VAR"} with default value in function call when "VAR" does
  not exists
  """ do
    Application.put_env(:test, :test_var, {:system, "TEST_VAR"})

    assert Config.get(:test, :test_var, "function default") == "function default"
  end

  test """
  Handles {:system, "VAR", default} with default value in config when no default
  is provided on function call when "VAR" does not exists
  """ do
    Application.put_env(:test, :test_var, {:system, "TEST_VAR", "config default"})

    assert Config.get(:test, :test_var) == "config default"
  end

  test """
  Handles {:system, "VAR", default} with default value in config even when a
  default is provided on function call when "VAR" does not exists
  """ do
    Application.put_env(:test, :test_var, {:system, "TEST_VAR", "config default"})

    assert Config.get(:test, :test_var, "function default") == "config default"
  end

  test """
  Handles nested lookup of simple values
  """ do
    Application.put_env(:test, :test_var, %{test: "hello"})

    assert Config.get(:test, [:test_var, :test]) == "hello"
  end

  test """
  Handles nested lookup of {:system "VAR"}
  """ do
    Application.put_env(:test, :test_var, %{test: {:system, "TEST_VAR"}})
    System.put_env("TEST_VAR", "env value")

    assert Config.get(:test, [:test_var, :test]) == "env value"
  end

  test """
  lookup works for top level keys
  """ do
    assert Config.lookup(%{test_var: "simple"}, :test_var) == "simple"
  end

  test """
  lookup works for nested keys
  """ do
    assert Config.lookup(%{test_var: %{test: "hello"}}, [:test_var, :test]) == "hello"
  end
end
