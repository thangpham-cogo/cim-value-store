defmodule Cim.LuaInterpreterTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  alias Cim.LuaInterpreter

  test "can handle multiline script" do
    script = """
    function test()
      return "hello world"
    end
    return test()
    """

    assert {:ok, "hello world"} = LuaInterpreter.eval("db", script)
  end

  test "can use cim.read/1, cim.write/2, and cim.delete/1 in script" do
    database = "db"
    key = "key"
    value = "value"

    expect(MockStore, :get, fn ^database, ^key -> {:ok, value} end)
    expect(MockStore, :put, fn ^database, ^key, ^value -> :ok end)
    expect(MockStore, :drop_key, fn ^database, ^key -> {:ok, {value, %{database => %{}}}} end)

    script = """
    cim.write("key", "value")
    cim.read("key")
    cim.delete("key")
    """

    assert {:ok, ""} = LuaInterpreter.eval(database, script)
  end
end
