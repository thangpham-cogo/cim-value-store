defmodule Cim.StoreBehavior do
  @moduledoc """
  Public API for Cim Store, useful for mocking in test
  """

  alias Cim.Store

  @callback get(Store.database(), Store.key()) ::
              {:ok, Store.value()} | {:error, :not_found}
  @callback put(Store.database(), Store.key(), Store.value()) :: :ok
  @callback drop_database(Store.database()) :: :ok | {:error, :not_found}
  @callback drop_key(Store.database(), Store.key()) ::
              {:ok, Store.value()} | {:error, :not_found}
  @callback has_database?(Store.database()) :: boolean()
end
