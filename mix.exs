defmodule Conduit.Mixfile do
  use Mix.Project

  def project do
    [app: :conduit,
     version: "0.2.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     # Docs
     name: "Conduit",
     source_url: "https://github.com/conduitframework/conduit",
     homepage_url: "https://hexdocs.pm/conduit",

     # Package
     description: "Message queue framework, with support for middleware and multiple adapters.",
     package: package,

     aliases: ["publish": ["hex.publish", &git_tag/1]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :timex]]
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
    [{:uuid, "~> 1.1"},
     {:timex, "~> 3.0"},
     {:ex_doc, "~> 0.14", only: :dev},
     {:poison, "~> 3.0"}]
  end

  defp package do
    [# These are the default files included in the package
     name: :conduit,
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Allen Madsen"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/conduitframework/conduit",
              "Docs" => "https://hexdocs.pm/conduit"}]
  end

  defp git_tag(_args) do
    tag = "v" <> Mix.Project.config[:version]
    System.cmd("git", ["tag", tag])
    System.cmd("git", ["push", "origin", tag])
  end
end
