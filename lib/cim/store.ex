defmodule Cim.Store do
  @moduledoc """
  Global type definition for store, database, key, and value
  """

  @type database :: any
  @type key :: any
  @type value :: binary
  @type t() :: %{database => %{key => value}}
end
