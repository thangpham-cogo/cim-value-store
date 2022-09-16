defmodule Cim.LuaInterpreterTest do
  use ExUnit.Case, async: true

  alias Cim.{StoreServer, LuaInterpreter}

  setup do
    db = "lua_store"
    key = "key"
    value = "value"
    StoreServer.put(db, key, value)

    {:ok, db: db, key: key, value: value}
  end

  describe "eval/2" do
    test "handle single-line script", ctx do
      script = ~s|return "hello world"|

      assert {:ok, "hello world"} = LuaInterpreter.eval(ctx.db, script)
    end

    test "handle multiline script", ctx do
      script = """
      function test()
        return "hello world"
      end
      return test()
      """

      assert {:ok, "hello world"} = LuaInterpreter.eval(ctx.db, script)
    end

    test "can use all of cim store functions", ctx do
      # thanks Arthur for inspiration
      script = """
      cim.write("ef0", 0.5)
      cim.delete("ef0")
      cim.write("ef1", 0.25)
      cim.write("amount", 100)
      cim.write("qcaf", 1.3)
      cim.write("shower-reduction-minutes", 2)

      ef = cim.read("ef0")
      if not ef then ef = cim.read("ef1") end

      amount = cim.read("amount")
      qcaf = cim.read("qcaf")
      n = cim.read("shower-reduction-minutes")

      footprint = amount * ef
      savings = footprint * ((n * qcaf) / (1 - (n * qcaf)))
      return savings
      """

      assert {:ok, -40.625} = LuaInterpreter.eval(ctx.db, script)
    end

    test "returns nil as is", ctx do
      script = ~s|return nil|

      assert {:ok, nil} = LuaInterpreter.eval(ctx.db, script)
    end

    test "returns nil for empty return", ctx do
      script = ~s|return|

      assert {:ok, nil} = LuaInterpreter.eval(ctx.db, script)
    end

    test "returns boolean as is", ctx do
      script = ~s|return true|
      assert {:ok, true} = LuaInterpreter.eval(ctx.db, script)

      script = ~s|return false|
      assert {:ok, false} = LuaInterpreter.eval(ctx.db, script)
    end

    test "returns list of tuples for Lua table", ctx do
      script = ~s|return {}|
      assert {:ok, []} = LuaInterpreter.eval(ctx.db, script)

      script = ~s|a = {} a.foo = "bar" a.bar = "foo" return a|
      assert {:ok, [{"bar", "foo"}, {"foo", "bar"}]} = LuaInterpreter.eval(ctx.db, script)
    end

    test "returns syntax error for invalid script", ctx do
      script = ~s|a = []|
      assert {:error, :syntax_error} = LuaInterpreter.eval(ctx.db, script)
    end
  end

  describe "cim.read/1" do
    test "returns value if key is set", ctx do
      script = ~s|return cim.read("#{ctx.key}")|

      assert {:ok, ctx.value} == LuaInterpreter.eval(ctx.db, script)
    end

    test "returns nil if key not set", ctx do
      script = ~s|return cim.read("unknown_key")|

      assert {:ok, nil} == LuaInterpreter.eval(ctx.db, script)
    end
  end

  describe "cim.write/2" do
    test "returns ok if writing to key succeeds", ctx do
      script = ~s|return cim.write("new_key", "value")|

      assert {:ok, "ok"} = LuaInterpreter.eval(ctx.db, script)
    end

    test "written data can be retrieved later in script", ctx do
      script = """
      cim.write("new_key", "value")
      return cim.read("new_key")
      """

      assert {:ok, "value"} = LuaInterpreter.eval(ctx.db, script)
    end

    test "writes string value into the key", ctx do
      script = """
      cim.write("new_key", 12)
      return type(cim.read("new_key"))
      """

      assert {:ok, "string"} == LuaInterpreter.eval(ctx.db, script)
    end
  end

  describe "cim.delete/1" do
    test "returns deleted value if key is set", ctx do
      script = ~s|return cim.delete("#{ctx.key}")|

      assert {:ok, ctx.value} == LuaInterpreter.eval(ctx.db, script)
    end

    test "returns nil if key is not set", ctx do
      script = ~s|return cim.delete("unknown_key")|

      assert {:ok, nil} == LuaInterpreter.eval(ctx.db, script)
    end
  end
end
