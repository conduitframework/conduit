defmodule Conduit.Mixfile do
  @moduledoc """
  Project config
  """
  use Mix.Project

  def project do
    [
      app: :conduit,
      version: "0.12.10",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Conduit",
      source_url: "https://github.com/conduitframework/conduit",
      homepage_url: "https://hexdocs.pm/conduit",
      docs: docs(),

      # Package
      description: "Message queue framework, with support for middleware and multiple adapters.",
      package: package(),
      dialyzer: [
        flags: ["-Werror_handling", "-Wrace_conditions"],
        plt_add_apps: [:mix],
        ignore_warnings: "dialyzer.ignore-warnings"
      ],

      # Coveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.circle": :test],
      aliases: [publish: ["hex.publish", &git_tag/1]]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger, :eex]]
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
    [
      {:elixir_uuid, "~> 1.1"},
      {:timex, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.19.0", only: [:dev]},
      {:dialyxir, "1.0.0-rc.4", only: [:dev], runtime: false},
      {:junit_formatter, "~> 2.0", only: :test},
      {:excoveralls, "~> 0.5", only: :test},
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:inch_ex, "~> 2.0", only: [:dev, :test]}
    ]
  end

  defp package do
    # These are the default files included in the package
    [
      name: :conduit,
      files: ["lib", "mix.exs", "README*", "LICENSE*", ".formatter.exs"],
      maintainers: ["Allen Madsen"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/conduitframework/conduit",
        "Docs" => "https://hexdocs.pm/conduit"
      }
    ]
  end

  defp docs do
    [
      logo: "logo.png",
      main: "readme",
      project: "Conduit",
      extra_section: "Guides",
      extras: ["README.md"],
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      Message: [
        "Conduit.Message"
      ],
      Broker: [
        "Conduit.Broker",
        "Conduit.Broker.DSL"
      ],
      Subscriber: [
        "Conduit.Subscriber"
      ],
      Plugs: [
        "Conduit.Plug",
        "Conduit.Plug.AckException",
        "Conduit.Plug.Builder",
        "Conduit.Plug.CorrelationId",
        "Conduit.Plug.CreatedAt",
        "Conduit.Plug.CreatedBy",
        "Conduit.Plug.DeadLetter",
        "Conduit.Plug.Decode",
        "Conduit.Plug.Encode",
        "Conduit.Plug.Format",
        "Conduit.Plug.LogIncoming",
        "Conduit.Plug.LogOutgoing",
        "Conduit.Plug.MessageActions",
        "Conduit.Plug.MessageId",
        "Conduit.Plug.NackException",
        "Conduit.Plug.Parse",
        "Conduit.Plug.Retry",
        "Conduit.Plug.Unwrap",
        "Conduit.Plug.Wrap"
      ],
      Adapter: [
        "Conduit.Adapter"
      ],
      "Content Types": [
        "Conduit.ContentType",
        "Conduit.ContentType.ErlangBinary",
        "Conduit.ContentType.JSON",
        "Conduit.ContentType.Text"
      ],
      Encodings: [
        "Conduit.Encoding",
        "Conduit.Encoding.GZip",
        "Conduit.Encoding.Identity"
      ],
      Testing: [
        "Conduit.Test",
        "Conduit.TestAdapter"
      ],
      "Config Structs": [
        "Conduit.Topology.Exchange",
        "Conduit.Topology.Queue",
        "Conduit.PublishRoute",
        "Conduit.SubscribeRoute",
        "Conduit.Pipeline"
      ],
      Utils: [
        "Conduit.Util"
      ]
    ]
  end

  defp git_tag(_args) do
    tag = "v" <> Mix.Project.config()[:version]
    System.cmd("git", ["tag", tag])
    System.cmd("git", ["push", "origin", tag])
  end
end
