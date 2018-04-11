defmodule Conduit.TestSharedTest do
  use ExUnit.Case, async: false
  use Conduit.Test, shared: true

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

    assert_message_published %Conduit.Message{}
  end

  test "assert_message_published/2" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_published %Conduit.Message{}, to: "somewhere"
  end

  test "refute_message_published/1" do
    refute_message_published %Conduit.Message{}
  end

  test "refute_message_published/2" do
    refute_message_published %Conduit.Message{}, to: "somewhere"
  end

  test "assert_message_publish/1" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish %Conduit.Message{}
  end

  test "refute_message_publish/1" do
    refute_message_publish %Conduit.Message{}
  end
end

defmodule Conduit.TestUnsharedTest do
  use ExUnit.Case, async: true
  use Conduit.Test, shared: false

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

    assert_message_published %Conduit.Message{}
  end

  test "assert_message_published/2" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_published %Conduit.Message{}, to: "somewhere"
  end

  test "refute_message_published/1" do
    refute_message_published %Conduit.Message{}
  end

  test "refute_message_published/2" do
    refute_message_published %Conduit.Message{}, to: "somewhere"
  end

  test "assert_message_publish/1" do
    Broker.publish(:message, %Conduit.Message{})

    assert_message_publish %Conduit.Message{}
  end

  test "refute_message_publish/1" do
    refute_message_publish %Conduit.Message{}
  end
end
