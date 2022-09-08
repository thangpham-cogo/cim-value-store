defmodule Cim.StoreLogicsTest do
  use ExUnit.Case

  alias Cim.StoreLogics

  describe "get/3" do
    setup do
      store = %{
        "db" => %{
          "key" => "value"
        }
      }

      {:ok, store: store}
    end

    test "returns an ok tuple with the stored value given an existing database and key", ctx do
      assert {:ok, "value"} = StoreLogics.get(ctx.store, "db", "key")
    end

    test "returns an error tuple with not found as the reason if the database does not exist",
         ctx do
      assert {:error, :not_found} = StoreLogics.get(ctx.store, "unknown_db", "key")
    end

    test "returns an error tuple with not found as the reason if the key does not exist", ctx do
      assert {:error, :not_found} = StoreLogics.get(ctx.store, "db", "unknown_key")
    end
  end
end
