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
        |> Adder.run(2)

      assert message.body == 3
    end
  end
end
