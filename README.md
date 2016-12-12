# Conduit

A message queue framework, with support for middleware and multiple adapters.

## Installation

The package can be installed as:

  1. Add `conduit` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:conduit, "~> 0.5.0"}]
    end
    ```

  2. Ensure `conduit` is started before your application:

    ```elixir
    def application do
      [applications: [:conduit]]
    end
    ```

## Getting Started



## Creating a Broker

The Broker is responsible for describing how to setup your
message queue routing, defining subscribers, publishers, and
pipelines for subscribers and publishers. Here is an example
Broker that sets up it's queue, exchange, and defines a
subscribers and publishers.

```elixir
defmodule MyApp.Broker do
  use Conduit.Broker, otp_app: :my_app

  configure do
    exchange "amq.topic"

    queue "my_app.created.user", from: ["#.created.user"]
  end

  pipeline :in_tracking do
    plug Conduit.Plug.CorrelationId
    plug Conduit.Plug.LogIncoming
  end

  pipeline :error_handling do
    plug Conduit.Plug.DeadLetter, broker: MyApp.Broker, publish_to: :error
    plug Conduit.Plug.Retry, attempts: 5
  end

  pipeline :deserialize do
    plug Conduit.Plug.Decode, content_encoding: "gzip"
    plug Conduit.Plug.Parse, content_type: "application/json"
  end

  pipeline :out_tracking do
    plug Conduit.Plug.CorrelationId
    plug Conduit.Plug.CreatedBy, app: "my_app"
    plug Conduit.Plug.CreatedAt
    plug Conduit.Plug.LogOutgoing
  end

  pipeline :serialize do
    plug Conduit.Plug.Format, content_type: "application/json"
    plug Conduit.Plug.Encode, content_encoding: "gzip"
  end

  pipeline :error_destination do
    plug :put_destination, &(&1.source <> ".error")
  end

  incoming MyApp do
    pipe_through [:in_tracking, :error_handling, :deserialize]

    subscribe :welcome_email, WelcomeEmailSubscriber, from: "my_app.created.user"
    subscribe :setup_billing, BillingSubscriber, from: "my_app.created.user"
  end

  outgoing do
    pipe_through [:out_tracking, :serialize]

    publish :user_created, to: "my_app.created.user", exchange: "amq.topic"
  end

  outgoing do
    pipe_through [:error_destination, :out_tracking, :serialize]

    publish :error, exchange: "amq.topic"
  end
end
```
