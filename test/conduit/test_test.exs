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
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_published :message

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_published ^message_name
  end

  test "assert_message_published/2" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_published :message, %Conduit.Message{}

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_published ^message_name, %Conduit.Message{}
  end

  test "assert_message_published/3" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_published(:message, %Conduit.Message{}, to: "somewhere")

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_published(^message_name, %Conduit.Message{}, to: "somewhere")
  end

  test "refute_message_published/1" do
    refute_message_published :message

    message_name = :message
    refute_message_published ^message_name
  end

  test "refute_message_published/2" do
    refute_message_published :message, %Conduit.Message{}

    message_name = :message
    refute_message_published ^message_name, %Conduit.Message{}
  end

  test "refute_message_published/3" do
    refute_message_published(:message, %Conduit.Message{}, to: "somewhere")

    message_name = :message
    refute_message_published(^message_name, %Conduit.Message{}, to: "somewhere")
  end

  test "assert_message_publish/1" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish(:message)

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_publish(^message_name)
  end

  test "assert_message_publish/2" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish :message, %Conduit.Message{}

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_publish ^message_name, 10
  end

  test "assert_message_publish/3" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish(:message, %Conduit.Message{}, to: "somewhere")

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_publish(^message_name, %Conduit.Message{}, 10)
  end

  test "assert_message_publish/4" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish(:message, %Conduit.Message{}, [to: "somewhere"], 10)

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_publish(^message_name, %Conduit.Message{}, [to: "somewhere"], 10)
  end

  test "refute_message_publish/1" do
    refute_message_publish :message

    message_name = :message
    refute_message_publish ^message_name
  end

  test "refute_message_publish/2" do
    refute_message_publish :message, %Conduit.Message{}

    refute_message_publish :message, 10

    message_name = :message
    refute_message_publish ^message_name, %Conduit.Message{}

    refute_message_publish ^message_name, 10
  end

  test "refute_message_publish/3" do
    refute_message_publish(:message, %Conduit.Message{}, to: "somewhere")

    refute_message_publish(:message, %Conduit.Message{}, 10)

    message_name = :message
    refute_message_publish(^message_name, %Conduit.Message{}, to: "somewhere")

    refute_message_publish(^message_name, %Conduit.Message{}, 10)
  end

  test "refute_message_publish/4" do
    refute_message_publish(:message, %Conduit.Message{}, [to: "somewhere"], 10)

    message_name = :message
    refute_message_publish(^message_name, %Conduit.Message{}, [to: "somewhere"], 10)
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
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_published :message

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_published ^message_name
  end

  test "assert_message_published/2" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_published :message, %Conduit.Message{}

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_published ^message_name, %Conduit.Message{}
  end

  test "assert_message_published/3" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_published(:message, %Conduit.Message{}, to: "somewhere")

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_published(^message_name, %Conduit.Message{}, to: "somewhere")
  end

  test "refute_message_published/1" do
    refute_message_published :message

    message_name = :message
    refute_message_published ^message_name
  end

  test "refute_message_published/2" do
    refute_message_published :message, %Conduit.Message{}

    message_name = :message
    refute_message_published ^message_name, %Conduit.Message{}
  end

  test "refute_message_published/3" do
    refute_message_published(:message, %Conduit.Message{}, to: "somewhere")

    message_name = :message
    refute_message_published(^message_name, %Conduit.Message{}, to: "somewhere")
  end

  test "assert_message_publish/1" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish(:message)

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_publish(^message_name)
  end

  test "assert_message_publish/2" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish :message, %Conduit.Message{}

    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish :message, 10

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_publish ^message_name, %Conduit.Message{}

    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish ^message_name, 10
  end

  test "assert_message_publish/3" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish(:message, %Conduit.Message{}, to: "somewhere")

    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish(:message, %Conduit.Message{}, 10)

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_publish(^message_name, %Conduit.Message{}, to: "somewhere")

    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish(^message_name, %Conduit.Message{}, 10)
  end

  test "assert_message_publish/4" do
    Broker.publish(%Conduit.Message{}, :message)

    assert_message_publish(:message, %Conduit.Message{}, [to: "somewhere"], 10)

    Broker.publish(%Conduit.Message{}, :message)

    message_name = :message
    assert_message_publish(^message_name, %Conduit.Message{}, [to: "somewhere"], 10)
  end

  test "refute_message_publish/1" do
    refute_message_publish :message

    message_name = :message
    refute_message_publish ^message_name
  end

  test "refute_message_publish/2" do
    refute_message_publish :message, %Conduit.Message{}

    refute_message_publish :message, 10

    message_name = :message
    refute_message_publish ^message_name, %Conduit.Message{}

    refute_message_publish ^message_name, 10
  end

  test "refute_message_publish/3" do
    refute_message_publish(:message, %Conduit.Message{}, to: "somewhere")

    refute_message_publish(:message, %Conduit.Message{}, 10)

    message_name = :message
    refute_message_publish(^message_name, %Conduit.Message{}, to: "somewhere")

    refute_message_publish(^message_name, %Conduit.Message{}, 10)
  end

  test "refute_message_publish/4" do
    refute_message_publish(:message, %Conduit.Message{}, [to: "somewhere"], 10)

    message_name = :message
    refute_message_publish(^message_name, %Conduit.Message{}, [to: "somewhere"], 10)
  end
end
