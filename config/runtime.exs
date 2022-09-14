import Config

config :cim, Cim.StoreServer, port: System.get_env("CIM_PORT", "3000")
