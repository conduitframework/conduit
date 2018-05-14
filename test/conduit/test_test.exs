defmodule Conduit.TestSharedTest do
  use ExUnit.Case, async: false
  use Conduit.Test, shared: true
  import ExUnit.CaptureIO

  setup do
    Application.put_env(
      :shared_test_app,
      Conduit.TestSharedTest.Broker,
      adapter: Conduit.TestAdapter
    )

    :ok
  end

  defmodule Broker do
    @moduledoc false
    use Conduit.Broker, otp_app: :shared_test_app

    outgoing do
      publish :message, to: "somewhere"
    end
  end

  test "assert_message_published/1" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_published :message

    Broker.publish(:message, %Conduit.Message{})

    assert capture_io(:stderr, fn ->
             assert_message_published %Conduit.Message{}
           end) =~ "Calling assert_message_published"
  end

  test "assert_message_published/2" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_published :message, %Conduit.Message{}

    Broker.publish(:message, %Conduit.Message{})

    assert capture_io(:stderr, fn ->
             assert_message_published %Conduit.Message{}, to: "somewhere"
           end) =~ "Calling assert_message_published"
  end

  test "assert_message_published/3" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_published(:message, %Conduit.Message{}, to: "somewhere")
  end

  test "refute_message_published/1" do
    refute_message_published :message

    assert capture_io(:stderr, fn ->
             refute_message_published %Conduit.Message{}
           end) =~ "Calling refute_message_published"
  end

  test "refute_message_published/2" do
    refute_message_published :message, %Conduit.Message{}

    assert capture_io(:stderr, fn ->
             refute_message_published %Conduit.Message{}, to: "somewhere"
           end) =~ "Calling refute_message_published"
  end

  test "refute_message_published/3" do
    refute_message_published(:message, %Conduit.Message{}, to: "somewhere")
  end

  test "assert_message_publish/1" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish(:message)

    Broker.publish(:message, %Conduit.Message{})

    assert capture_io(:stderr, fn ->
             assert_message_publish %Conduit.Message{}
           end) =~ "Calling assert_message_publish"
  end

  test "assert_message_publish/2" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish :message, %Conduit.Message{}

    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish :message, 10
  end

  test "assert_message_publish/3" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish(:message, %Conduit.Message{}, to: "somewhere")

    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish(:message, %Conduit.Message{}, 10)
  end

  test "assert_message_publish/4" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish(:message, %Conduit.Message{}, [to: "somewhere"], 10)
  end

  test "refute_message_publish/1" do
    refute_message_publish :message

    assert capture_io(:stderr, fn ->
             refute_message_publish %Conduit.Message{}
           end) =~ "Calling refute_message_publish"
  end

  test "refute_message_publish/2" do
    refute_message_publish :message, %Conduit.Message{}

    refute_message_publish :message, 10

    assert capture_io(:stderr, fn ->
             refute_message_publish %Conduit.Message{}, 10
           end) =~ "Calling refute_message_publish"
  end

  test "refute_message_publish/3" do
    refute_message_publish(:message, %Conduit.Message{}, to: "somewhere")

    refute_message_publish(:message, %Conduit.Message{}, 10)
  end

  test "refute_message_publish/4" do
    refute_message_publish(:message, %Conduit.Message{}, [to: "somewhere"], 10)
  end
end

defmodule Conduit.TestUnsharedTest do
  use ExUnit.Case, async: true
  use Conduit.Test, shared: false
  import ExUnit.CaptureIO

  setup do
    Application.put_env(
      :unshared_test_app,
      Conduit.TestUnsharedTest.Broker,
      adapter: Conduit.TestAdapter
    )

    :ok
  end

  defmodule Broker do
    use Conduit.Broker, otp_app: :unshared_test_app

    outgoing do
      publish :message, to: "somewhere"
    end
  end

  test "assert_message_published/1" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_published :message

    Broker.publish(:message, %Conduit.Message{})

    assert capture_io(:stderr, fn ->
             assert_message_published %Conduit.Message{}
           end) =~ "Calling assert_message_published"
  end

  test "assert_message_published/2" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_published :message, %Conduit.Message{}

    Broker.publish(:message, %Conduit.Message{})

    assert capture_io(:stderr, fn ->
             assert_message_published %Conduit.Message{}, to: "somewhere"
           end) =~ "Calling assert_message_published"
  end

  test "assert_message_published/3" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_published(:message, %Conduit.Message{}, to: "somewhere")
  end

  test "refute_message_published/1" do
    refute_message_published :message

    assert capture_io(:stderr, fn ->
             refute_message_published %Conduit.Message{}
           end) =~ "Calling refute_message_published"
  end

  test "refute_message_published/2" do
    refute_message_published :message, %Conduit.Message{}

    assert capture_io(:stderr, fn ->
             refute_message_published %Conduit.Message{}, to: "somewhere"
           end) =~ "Calling refute_message_published"
  end

  test "refute_message_published/3" do
    refute_message_published(:message, %Conduit.Message{}, to: "somewhere")
  end

  test "assert_message_publish/1" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish(:message)

    Broker.publish(:message, %Conduit.Message{})

    assert capture_io(:stderr, fn ->
             assert_message_publish %Conduit.Message{}
           end) =~ "Calling assert_message_publish"
  end

  test "assert_message_publish/2" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish :message, %Conduit.Message{}

    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish :message, 10
  end

  test "assert_message_publish/3" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish(:message, %Conduit.Message{}, to: "somewhere")

    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish(:message, %Conduit.Message{}, 10)
  end

  test "assert_message_publish/4" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish(:message, %Conduit.Message{}, [to: "somewhere"], 10)
  end

  test "refute_message_publish/1" do
    refute_message_publish :message

    assert capture_io(:stderr, fn ->
             refute_message_publish %Conduit.Message{}
           end) =~ "Calling refute_message_publish"
  end

  test "refute_message_publish/2" do
    refute_message_publish :message, %Conduit.Message{}

    refute_message_publish :message, 10

    assert capture_io(:stderr, fn ->
             refute_message_publish %Conduit.Message{}, 10
           end) =~ "Calling refute_message_publish"
  end

  test "refute_message_publish/3" do
    refute_message_publish(:message, %Conduit.Message{}, to: "somewhere")

    refute_message_publish(:message, %Conduit.Message{}, 10)
  end

  test "refute_message_publish/4" do
    refute_message_publish(:message, %Conduit.Message{}, [to: "somewhere"], 10)
  end
end
