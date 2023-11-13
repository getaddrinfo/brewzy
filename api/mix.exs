defmodule Brew.MixProject do
  use Mix.Project

  def project do
    [
      app: :brew,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Brew.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"}, # http server
      {:jason, "~> 1.4"}, # json encoder/decoder
      {:vex, "~> 0.9.1"}, # validation

      # http client
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17"}
    ]
  end
end
