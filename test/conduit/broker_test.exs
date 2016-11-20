defmodule Conduit.BrokerTest do
  use ExUnit.Case

  defmodule PassThrough do
    use Conduit.Plug.Builder

    def call(message, _opts), do: message
  end

  defmodule MyApp.StuffSubscriber do
    use Conduit.Subscriber

    def call(message, _opts), do: message
  end

  defmodule Adapter do
    use Supervisor

    def start_link(topology, subscribers, opts) do
      Supervisor.start_link(__MODULE__, {topology, subscribers, opts}, name: __MODULE__)
    end

    def init(opts) do
      import Supervisor.Spec

      send(Conduit.BrokerTest, {:adapter, opts})

      supervise([], strategy: :one_for_one)
    end

    def publish(message, opts) do
      send(Conduit.BrokerTest, {:publish, message, opts})

      message
    end
  end

  defmodule Broker do
    use Conduit.Broker, otp_app: :my_app

    configure do
      exchange "amq.topic"

      queue "my_app.created.stuff", from: ["#.created.stuff"]
    end

    pipeline :incoming do
      plug PassThrough
    end

    pipeline :outgoing do
      plug PassThrough
    end

    incoming Conduit.BrokerTest.MyApp do
      pipe_through :incoming

      subscribe :stuff, StuffSubscriber, from: "my_app.created.stuff"
    end

    outgoing do
      pipe_through :outgoing

      publish :more_stuff, exchange: "amq.topic", to: "middle_out.created.more_stuff"
    end
  end

  describe ".start_link" do
    test "it starts the adapter and passes the setup and subscribers" do
      Process.register(self, __MODULE__)
      Application.put_env(:my_app, Broker, adapter: Adapter)

      Broker.start_link

      assert_received {:adapter, {
        [{:exchange, "amq.topic", []}, {:queue, "my_app.created.stuff", [from: ["#.created.stuff"]]}],
        %{stuff: {Conduit.BrokerTest.Broker.StuffIncoming, [from: "my_app.created.stuff"]}},
        [adapter: Conduit.BrokerTest.Adapter]
      }}
    end
  end

  describe ".publish" do
    test "it delegates to the adapter after passing through the pipeline" do
      Process.register(self, __MODULE__)
      Application.put_env(:my_app, Broker, adapter: Adapter)

      Broker.publish(:more_stuff, %Conduit.Message{})

      assert_received {:publish, %Conduit.Message{}, [exchange: "amq.topic", to: "middle_out.created.more_stuff"]}
    end
  end
end
