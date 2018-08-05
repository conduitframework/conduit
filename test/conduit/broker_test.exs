defmodule Conduit.BrokerTest do
  use ExUnit.Case
  use Conduit.Test, shared: true

  defmodule PassThrough do
    @moduledoc false
    use Conduit.Plug.Builder

    def call(message, next, opts) do
      send(self(), {:pass_through, message, opts})

      next.(message)
    end
  end

  defmodule MyApp.StuffSubscriber do
    @moduledoc false
    use Conduit.Subscriber

    def process(message, opts) do
      send(self(), {:subscriber, message, opts})

      message
    end
  end

  defmodule ListPrepender do
    @moduledoc false
    use Conduit.Plug.Builder

    def call(message, next, item) do
      new_list = [item | message.assigns[:list] || []]

      message
      |> Conduit.Message.assign(:list, new_list)
      |> next.()
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
      plug PassThrough, :incoming
    end

    pipeline :outgoing do
      plug PassThrough, :outgoing
    end

    pipeline :prepend1 do
      plug ListPrepender, 1
      plug ListPrepender, 2
    end

    pipeline :prepend2 do
      plug ListPrepender, 3
      plug ListPrepender, 4
    end

    incoming Conduit.BrokerTest.MyApp do
      pipe_through :incoming

      subscribe :stuff, StuffSubscriber, from: "my_app.created.stuff", other: :stuff
    end

    incoming Conduit.BrokerTest.MyApp do
      pipe_through [:prepend1, :prepend2]

      subscribe :prepend, StuffSubscriber, from: "my_app.created.prepend"
    end

    outgoing do
      pipe_through :outgoing

      publish :more_stuff, exchange: "amq.topic", to: "my_app.created.more_stuff"
    end

    outgoing do
      pipe_through [:prepend1, :prepend2]

      publish :prepend, exchange: "amq.topic", to: "my_app.created.more_stuff"
    end
  end

  describe "start_link/0" do
    test "it starts the adapter and passes the setup and subscribers" do
      Process.register(self(), __MODULE__)
      Application.put_env(:my_app, Broker, adapter: Conduit.TestAdapter)

      Broker.start_link()

      assert_received {:adapter,
                       [
                         Conduit.BrokerTest.Broker,
                         [
                           {:exchange, "amq.topic", []},
                           {:exchange, "dynamic.name", []},
                           {:queue, "my_app.created.stuff", [from: ["#.created.stuff"]]},
                           {:queue, "dynamic.name", [from: ["#"]]}
                         ],
                         %{stuff: [from: "my_app.created.stuff", other: :stuff]},
                         [adapter: Conduit.TestAdapter]
                       ]}
    end
  end

  describe "publish/2" do
    test "it delegates to the adapter after passing through the pipeline" do
      Process.register(self(), __MODULE__)
      Application.put_env(:my_app, Broker, adapter: Conduit.TestAdapter)

      Broker.publish(:more_stuff, %Conduit.Message{})

      assert_received {:pass_through, %Conduit.Message{}, :outgoing}

      assert_received {:publish, Broker, :more_stuff, %Conduit.Message{}, [adapter: Conduit.TestAdapter],
                       [exchange: "amq.topic", to: "my_app.created.more_stuff"]}
    end

    test "plugs are called in order" do
      Process.register(self(), __MODULE__)
      Application.put_env(:my_app, Broker, adapter: Conduit.TestAdapter)

      Broker.publish(:prepend, %Conduit.Message{})

      assert_received {:publish, Broker, :prepend, message, _, _}

      assert message.assigns.list == [4, 3, 2, 1]
    end

    @expected_message """
    Undefined publish route :non_existent.

    Perhaps :non_existent is misspelled. Otherwise, it can be defined in Conduit.BrokerTest.Broker by adding:

        outgoing do
          publish :non_existent, to: "my.destination", other: "options"
        end
    """
    test "it produces a useful error when publishing to an undefined publish route" do
      assert_raise Conduit.UndefinedPublishRouteError, @expected_message, fn ->
        Broker.publish(:non_existent, %Conduit.Message{})
      end
    end
  end

  describe "receives/2" do
    test "it calls the subscriber and it's pipeline" do
      Broker.receives(:stuff, %Conduit.Message{})

      assert_received {:pass_through, %Conduit.Message{}, :incoming}

      assert_received {:subscriber, %Conduit.Message{}, from: "my_app.created.stuff", other: :stuff}
    end

    test "plugs are called in order" do
      Broker.receives(:prepend, %Conduit.Message{})

      assert_received {:subscriber, message, _}

      assert message.assigns.list == [4, 3, 2, 1]
    end

    @expected_message """
    Undefined subscribe route :non_existent.

    Perhaps :non_existent is misspelled. Otherwise, it can be defined in Conduit.BrokerTest.Broker by adding:

        incoming MyApp do
          subscribe :non_existent, MySubscriber, from: "my.source", other: "options"
        end
    """
    test "it produces a useful error when receiving for an undefined subscribe route" do
      assert_raise Conduit.UndefinedSubscribeRouteError, @expected_message, fn ->
        Broker.receives(:non_existent, %Conduit.Message{})
      end
    end
  end
end
