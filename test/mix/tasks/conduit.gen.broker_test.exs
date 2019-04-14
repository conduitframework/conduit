defmodule Mix.Tasks.Conduit.Gen.BrokerTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Conduit.Gen.Broker, as: GenBroker

  setup do
    File.rm_rf("tmp")

    on_exit(fn ->
      File.rm_rf("tmp")
    end)

    :ok
  end

  describe "run/1" do
    test "raises exception when invalid switch is passed" do
      assert_raise OptionParser.ParseError, fn ->
        GenBroker.run(["foo", "--something-broken"])
      end
    end

    test "prints broker being created and info about other files to update for ConduitAMQP" do
      io =
        capture_io(fn ->
          GenBroker.run(["tmp/lib/conduit_queue"])
        end)

      assert io == """
             \e[32m* creating \e[0mtmp/lib/conduit_queue\e[0m
             \e[32m* creating \e[0mtmp/lib/conduit_queue/broker.ex\e[0m

             Add conduit_amqp to your dependencies in mix.exs:

                 {:conduit_amqp, "~> 0.6.3"}

             Make sure to add the following to your config.exs:

                 config :conduit, ConduitQueue.Broker,
                   adapter: ConduitAMQP,
                   url: "amqp://guest:guest@localhost:6782"

             Also, add your broker to the supervision hierarchy in your conduit.ex:

             Elixir v1.5 or above:

                 def start(_type, _args) do
                   children = [
                     # ...
                     {ConduitQueue.Broker, []}
                   ]

                   opts = [strategy: :one_for_one]

                   Supervisor.start_link(children, opts)
                 end

             Elixir v1.4 or below:

                 def start(_type, _args) do
                   children = [
                     # ...
                     supervisor(ConduitQueue.Broker, [])
                   ]

                   supervise(children, strategy: :one_for_one)
                 end

             """
    end

    test "prints broker being created and info about other files to update for ConduitSQS" do
      io =
        capture_io(fn ->
          GenBroker.run(["--adapter", "sqs"])
        end)

      assert io == """
             \e[32m* creating \e[0mtmp/lib/conduit_queue\e[0m
             \e[32m* creating \e[0mtmp/lib/conduit_queue/broker.ex\e[0m

             Add conduit_sqs to your dependencies in mix.exs:

                 {:conduit_sqs, "~> 0.2.7"}

             Make sure to add the following to your config.exs:

                 config :conduit, ConduitQueue.Broker,
                   adapter: ConduitSQS,
                   access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
                   secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

             Also, add your broker to the supervision hierarchy in your conduit.ex:

             Elixir v1.5 or above:

                 def start(_type, _args) do
                   children = [
                     # ...
                     {ConduitQueue.Broker, []}
                   ]

                   opts = [strategy: :one_for_one]

                   Supervisor.start_link(children, opts)
                 end

             Elixir v1.4 or below:

                 def start(_type, _args) do
                   children = [
                     # ...
                     supervisor(ConduitQueue.Broker, [])
                   ]

                   supervise(children, strategy: :one_for_one)
                 end

             """
    end

    test "creates broker in expected directory" do
      capture_io(fn ->
        GenBroker.run([])
      end)

      assert File.exists?("tmp/lib/conduit_queue/broker.ex")
    end

    test "creates broker in expected directory based on module name" do
      capture_io(fn ->
        GenBroker.run(["--module", "MyApp.Broker"])
      end)

      assert File.exists?("tmp/lib/my_app/broker.ex")

      contents = File.read!("tmp/lib/my_app/broker.ex")
      assert contents =~ "defmodule MyApp.Broker do"
    end

    test "generates the broker with the expected content for amqp" do
      capture_io(fn ->
        GenBroker.run([])
      end)

      contents = File.read!("tmp/lib/conduit_queue/broker.ex")

      assert contents == """
             defmodule ConduitQueue.Broker do
               use Conduit.Broker, otp_app: :conduit

               configure do
                 # queue "conduit.queue"
               end

               # pipeline :in_tracking do
               #   plug Conduit.Plug.CorrelationId
               #   plug Conduit.Plug.LogIncoming
               # end

               # pipeline :error_handling do
               #   plug Conduit.Plug.DeadLetter, broker: ConduitQueue.Broker, publish_to: :error
               #   plug Conduit.Plug.Retry, attempts: 5
               # end

               # pipeline :deserialize do
               #   plug Conduit.Plug.Decode, content_encoding: "gzip"
               #   plug Conduit.Plug.Parse, content_type: "application/json"
               # end

               incoming ConduitQueue do
                 # subscribe :my_subscription, MySubscriber, from: "conduit.queue"
               end

               # pipeline :out_tracking do
               #   plug Conduit.Plug.CorrelationId
               #   plug Conduit.Plug.CreatedBy, app: "conduit"
               #   plug Conduit.Plug.CreatedAt
               #   plug Conduit.Plug.LogOutgoing
               # end

               # pipeline :serialize do
               #   plug Conduit.Plug.Format, content_type: "application/json"
               #   plug Conduit.Plug.Encode, content_encoding: "gzip"
               # end

               # pipeline :error_destination do
               #   plug :put_destination, &(&1.source <> ".error")
               # end

               outgoing do
                 # pipe_through [:out_tracking, :serialize]

                 # publish :my_event, to: "conduit.my_event"
               end

               # outgoing do
               #   pipe_through [:error_destination, :out_tracking, :serialize]

               #   publish :error, exchange: "amq.topic"
               # end

             end
             """
    end

    test "generates the broker with the expected content for sqs" do
      capture_io(fn ->
        GenBroker.run(["--adapter", "sqs"])
      end)

      contents = File.read!("tmp/lib/conduit_queue/broker.ex")

      assert contents == """
             defmodule ConduitQueue.Broker do
               use Conduit.Broker, otp_app: :conduit

               configure do
                 # queue "conduit-queue"
                 # queue "conduit-queue-error"
               end

               # pipeline :in_tracking do
               #   plug Conduit.Plug.CorrelationId
               #   plug Conduit.Plug.LogIncoming
               # end

               # pipeline :error_handling do
               #   plug Conduit.Plug.DeadLetter, broker: ConduitQueue.Broker, publish_to: :error
               #   plug Conduit.Plug.Retry, attempts: 5
               # end

               # pipeline :deserialize do
               #   plug Conduit.Plug.Decode, content_encoding: "gzip"
               #   plug Conduit.Plug.Parse, content_type: "application/json"
               # end

               incoming ConduitQueue do
                 # subscribe :my_subscription, MySubscriber, from: "conduit-queue"
               end

               # pipeline :out_tracking do
               #   plug Conduit.Plug.CorrelationId
               #   plug Conduit.Plug.CreatedBy, app: "conduit"
               #   plug Conduit.Plug.CreatedAt
               #   plug Conduit.Plug.LogOutgoing
               # end

               # pipeline :serialize do
               #   plug Conduit.Plug.Format, content_type: "application/json"
               #   plug Conduit.Plug.Encode, content_encoding: "gzip"
               # end

               # pipeline :error_destination do
               #   plug :put_destination, &(&1.source <> "-error")
               # end

               outgoing do
                 # pipe_through [:out_tracking, :serialize]

                 # publish :my_event, to: "conduit-my-event"
               end

               # outgoing do
               #   pipe_through [:error_destination, :out_tracking, :serialize]

               #   publish :error
               # end

             end
             """
    end
  end
end
