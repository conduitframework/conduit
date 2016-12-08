defmodule Conduit.Plug.BuilderTest do
  use ExUnit.Case
  alias Conduit.Message
  import Conduit.Message
  doctest Conduit.Plug.Builder

  @identity &(&1)

  defmodule Adder do
    use Conduit.Plug.Builder

    def init(by: amount), do: amount

    def call(message, next, amount) do
      message
      |> put_body(message.body + amount)
      |> next.()
    end
  end

  describe "a plug that only defines call" do
    test "it is called as part of the plugs pipeline" do
      message =
        %Message{}
        |> put_body(1)
        |> Adder.run(by: 2)

      assert message.body == 3
    end
  end

  @error_message "Couldn't find module MissingPlug"
  test "raises error when module plug can't be found" do
    assert_raise Conduit.UnknownPlugError, @error_message, fn ->
      defmodule FailPlug do
        use Conduit.Plug.Builder

        plug MissingPlug
      end
    end
  end
end
