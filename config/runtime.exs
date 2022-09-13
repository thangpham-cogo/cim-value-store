import Config

config :cim, port: System.get_env("CIM_PORT", "3000")
