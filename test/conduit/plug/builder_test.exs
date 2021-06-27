defmodule Conduit.Plug.BuilderTest do
  use ExUnit.Case
  alias Conduit.Message
  import Conduit.Message
  doctest Conduit.Plug.Builder

  defmodule Adder do
    use Conduit.Plug.Builder

    def init(by: amount), do: amount

    def call(message, next, amount) do
      message
      |> put_body(message.body + amount)
      |> next.()
    end
  end

  defmodule Multiplier do
    use Conduit.Plug.Builder

    def call(message, next, by: amount) do
      message
      |> put_body(message.body * amount)
      |> next.()
    end
  end

  defmodule BodyChanger do
    use Conduit.Plug.Builder

    def call(message, next, fun) do
      message
      |> put_body(fun.(message.body))
      |> next.()
    end
  end

  describe "a plug that defines init and call" do
    defmodule PlusOne do
      use Conduit.Plug.Builder

      plug Adder, by: 1
    end

    test "it is called as part of a pipeline" do
      message =
        %Message{}
        |> put_body(1)
        |> PlusOne.run()

      assert message.body == 2
    end
  end

  describe "a plug that only defines and call" do
    defmodule TimesTwo do
      use Conduit.Plug.Builder

      plug Multiplier, by: 2
    end

    test "it is called as part of the plugs pipeline" do
      message =
        %Message{}
        |> put_body(1)
        |> TimesTwo.run()

      assert message.body == 2
    end
  end

  describe "a plug that accepts a function" do
    defmodule DivideTwo do
      use Conduit.Plug.Builder

      plug BodyChanger, fn body -> body / 2 end
    end

    test "it is called as part of the plugs pipeline" do
      message =
        %Message{}
        |> put_body(4)
        |> DivideTwo.run()

      assert message.body == 2
    end
  end

  describe "a plug that accepts a short hand function" do
    defmodule SubtractTwo do
      use Conduit.Plug.Builder

      plug BodyChanger, &(&1 - 2)
    end

    test "it is called as part of the plugs pipeline" do
      message =
        %Message{}
        |> put_body(4)
        |> SubtractTwo.run()

      assert message.body == 2
    end
  end

  @error_message "Module MissingPlug does not implement init/1 and __build__/2. Make sure to use Conduit.Plug."
  test "raises error when module plug can't be found" do
    assert_raise Conduit.UnknownPlugError, @error_message, fn ->
      defmodule FailPlug do
        use Conduit.Plug.Builder

        plug MissingPlug
      end
    end
  end
end
