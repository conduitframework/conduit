defmodule Conduit.Mixfile do
  use Mix.Project

  def project do
    [app: :conduit,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     name: "Conduit",
     source_url: "https://github.com/conduitframework/conduit",
     homepage_url: "https://hexdocs.pm/conduit"]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :amqp]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:amqp, "~> 0.1"},
     {:connection, "~> 1.0"},
     {:poolboy, "~> 1.5"},
     {:ex_crypto, "~> 0.1.1"},
     {:ex_doc, "~> 0.14", only: :dev}]
  end
end
