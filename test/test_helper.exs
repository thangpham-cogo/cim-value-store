Mox.defmock(MockStore, for: Cim.StoreBehavior)
Application.put_env(:cim, :store, MockStore)

ExUnit.start()
