defmodule Cim.MixProject do
  use Mix.Project

  def project do
    [
      app: :cim,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Cim.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:luerl, "~> 1.0.0"},
      {:plug_cowboy, "~> 2.0"},
      {:credo, "~> 1.6.6"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
