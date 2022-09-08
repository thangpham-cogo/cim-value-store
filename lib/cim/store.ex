defmodule Cim.Store do
  @moduledoc """
  A gen server for holding the store, dispatching client requests to and passing back response from StoreLogics
  """
  @type t :: %{String.t() => binary()}
end
