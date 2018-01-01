defmodule Conduit.BrokerTest do
  use ExUnit.Case
  use Conduit.Test, shared: true

  defmodule PassThrough do
    @moduledoc false
    use Conduit.Plug.Builder

    def call(message, next, _opts) do
      send(self(), {:pass_through, message})

      next.(message)
    end
  end

  defmodule MyApp.StuffSubscriber do
    @moduledoc false
    use Conduit.Subscriber

    def process(message, _opts) do
      send(self(), {:subscriber, message})

      message
    end
  end

  defmodule Broker do
    @moduledoc false
    use Conduit.Broker, otp_app: :my_app

    configure do
      exchange "amq.topic"
      exchange fn -> "dynamic.name" end

      queue "my_app.created.stuff", from: ["#.created.stuff"]
      queue fn -> "dynamic.name" end, from: ["#"]
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

      publish :more_stuff, exchange: "amq.topic", to: "my_app.created.more_stuff"
    end
  end

  describe "start_link/0" do
    test "it starts the adapter and passes the setup and subscribers" do
      Process.register(self(), __MODULE__)
      Application.put_env(:my_app, Broker, adapter: Conduit.TestAdapter)

      Broker.start_link

      assert_received {:adapter, [
        Conduit.BrokerTest.Broker,
        [
          {:exchange, "amq.topic", []},
          {:exchange, "dynamic.name", []},
          {:queue, "my_app.created.stuff", [from: ["#.created.stuff"]]},
          {:queue, "dynamic.name", [from: ["#"]]}
        ],
        %{stuff: [from: "my_app.created.stuff"]},
        [adapter: Conduit.TestAdapter]
      ]}
    end
  end

  describe "publish/2" do
    test "it delegates to the adapter after passing through the pipeline" do
      Process.register(self(), __MODULE__)
      Application.put_env(:my_app, Broker, adapter: Conduit.TestAdapter)

      Broker.publish(:more_stuff, %Conduit.Message{})

      assert_received {:pass_through, %Conduit.Message{}}
      assert_received {:publish, %Conduit.Message{}, [adapter: Conduit.TestAdapter], [exchange: "amq.topic", to: "my_app.created.more_stuff"]}
    end
  end

  describe "receives/2" do
    test "it calls the subscriber and it's pipeline" do
      Broker.receives(:stuff, %Conduit.Message{})

      assert_received {:pass_through, %Conduit.Message{}}
      assert_received {:subscriber, %Conduit.Message{}}
    end
  end
end
