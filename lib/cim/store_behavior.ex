defmodule Cim.StoreBehavior do
  @moduledoc """
  Public API for Cim Store, useful for mocking in test
  """

  @callback get(database :: String.t(), key :: String.t()) ::
              {:ok, value :: binary()} | {:error, :not_found}

  @callback put(database :: String.t(), key :: String.t(), value :: binary()) :: :ok
  @callback drop_database(database :: String.t()) :: :ok | {:error, :not_found}
  @callback drop_key(database :: String.t(), key :: String.t()) :: :ok | {:error, :not_found}
  @callback has_database?(database :: String.t()) :: boolean()
end
