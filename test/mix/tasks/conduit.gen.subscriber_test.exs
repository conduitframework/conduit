defmodule Mix.Tasks.Conduit.Gen.SubscriberTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Conduit.Gen.Subscriber, as: GenSubscriber

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
        GenSubscriber.run(["foo", "--something-broken"])
      end
    end

    test "raises exception when the broker is not configured" do
      assert_raise ArgumentError, fn ->
        GenSubscriber.run(["foo", "--broker", "NonExistent.Broker"])
      end
    end

    test "raises exception when the broker is not configured with an adapter" do
      assert_raise ArgumentError, fn ->
        GenSubscriber.run(["foo", "--broker", "NoAdapter.Broker"])
      end
    end

    test "prints subscriber being created and info about other files to update when adapter is AMQP" do
      io =
        capture_io(fn ->
          GenSubscriber.run(["foo"])
        end)

      assert io == """
             \e[32m* creating \e[0mtmp/lib/conduit_queue/subscribers\e[0m
             \e[32m* creating \e[0mtmp/lib/conduit_queue/subscribers/foo_subscriber.ex\e[0m
             \e[32m* creating \e[0mtmp/test/conduit_queue/subscribers/foo_subscriber_test.exs\e[0m

             In an outgoing block in your ConduitQueue.Broker add:

                 subscribe :foo, FooSubscriber, to: "conduit.foo"

             You may also want to define the queue in the configure block for ConduitQueue.Broker:

                 queue "conduit.foo"

             """
    end

    test "prints subscriber being created and info about other files to update when adapter is SQS" do
      io =
        capture_io(fn ->
          GenSubscriber.run(["foo", "--broker", "Sqs.Broker"])
        end)

      assert io == """
             \e[32m* creating \e[0mtmp/lib/sqs/subscribers\e[0m
             \e[32m* creating \e[0mtmp/lib/sqs/subscribers/foo_subscriber.ex\e[0m
             \e[32m* creating \e[0mtmp/test/sqs/subscribers/foo_subscriber_test.exs\e[0m

             In an outgoing block in your Sqs.Broker add:

                 subscribe :foo, FooSubscriber, to: "conduit-foo"

             You may also want to define the queue in the configure block for Sqs.Broker:

                 queue "conduit-foo"

             """
    end

    test "creates subscriber in expected directory" do
      capture_io(fn ->
        GenSubscriber.run(["foo"])
      end)

      assert File.exists?("tmp/lib/conduit_queue/subscribers/foo_subscriber.ex")
      assert File.exists?("tmp/test/conduit_queue/subscribers/foo_subscriber_test.exs")
    end

    test "generates the subscriber with the expected content" do
      capture_io(fn ->
        GenSubscriber.run(["foo"])
      end)

      contents = File.read!("tmp/lib/conduit_queue/subscribers/foo_subscriber.ex")

      assert contents == """
             defmodule ConduitQueue.FooSubscriber do
               use Conduit.Subscriber

               def process(message, _opts) do


                 message
               end
             end
             """
    end

    test "generates the subscriber test with the expected content" do
      capture_io(fn ->
        GenSubscriber.run(["foo"])
      end)

      contents = File.read!("tmp/test/conduit_queue/subscribers/foo_subscriber_test.exs")

      assert contents == """
             defmodule ConduitQueue.FooSubscriberTest do
               use ExUnit.Case
               use Conduit.Test
               import Conduit.Message
               alias Conduit.Message
               alias ConduitQueue.FooSubscriber

               describe "process/2" do
                 test "returns acked message" do
                   message =
                     %Message{}
                     |> put_body("foo")

                   assert %Message{status: :ack} = FooSubscriber.run(message)
                 end
               end
             end
             """
    end

    test "creates subscriber in expected directory with broker flag" do
      capture_io(fn ->
        GenSubscriber.run(["foo", "--broker", "MyApp.Broker"])
      end)

      assert File.exists?("tmp/lib/my_app/subscribers/foo_subscriber.ex")
      assert File.exists?("tmp/test/my_app/subscribers/foo_subscriber_test.exs")
    end

    test "generates the subscriber with the expected content with broker flag" do
      capture_io(fn ->
        GenSubscriber.run(["foo", "--broker", "MyApp.Broker"])
      end)

      contents = File.read!("tmp/lib/my_app/subscribers/foo_subscriber.ex")

      assert contents == """
             defmodule MyApp.FooSubscriber do
               use Conduit.Subscriber

               def process(message, _opts) do


                 message
               end
             end
             """
    end

    test "generates the subscriber test with the expected content with broker flag" do
      capture_io(fn ->
        GenSubscriber.run(["foo", "--broker", "MyApp.Broker"])
      end)

      contents = File.read!("tmp/test/my_app/subscribers/foo_subscriber_test.exs")

      assert contents == """
             defmodule MyApp.FooSubscriberTest do
               use ExUnit.Case
               use Conduit.Test
               import Conduit.Message
               alias Conduit.Message
               alias MyApp.FooSubscriber

               describe "process/2" do
                 test "returns acked message" do
                   message =
                     %Message{}
                     |> put_body("foo")

                   assert %Message{status: :ack} = FooSubscriber.run(message)
                 end
               end
             end
             """
    end
  end
end
