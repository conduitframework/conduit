defmodule Conduit.UtilTest do
  use ExUnit.Case
  alias Conduit.Util

  describe "retry" do
    test "only executes once if successful" do
      Process.register(self(), __MODULE__)

      Util.retry(fn ->
        send(Conduit.UtilTest, :attempt)
      end)

      assert_received :attempt
      refute_received :attempt
    end

    test "retries the attempts specified" do
      Process.register(self(), __MODULE__)

      Util.retry([attempts: 3, delay: 0], fn ->
        send(Conduit.UtilTest, :attempt)
        {:error, :reattempt}
      end)

      assert_received :attempt
      assert_received :attempt
      assert_received :attempt
      refute_received :attempt
    end

    test "generates the expected delays" do
      Process.register(self(), __MODULE__)

      Util.retry([attempts: 5, delay: 1, max_delay: 6, backoff_factor: 2], fn delay ->
        send(Conduit.UtilTest, {:attempt, delay})
        {:error, :reattempt}
      end)

      assert_received {:attempt, 0}
      assert_received {:attempt, 2}
      assert_received {:attempt, 4}
      assert_received {:attempt, 6}
      assert_received {:attempt, 6}
      refute_received {:attempt, _}
    end
  end

  describe "wait_until" do
    test "returns when condition is true" do
      Process.register(self(), __MODULE__)

      result =
        Util.wait_until(fn ->
          send(Conduit.UtilTest, :attempt)
          true
        end)

      assert :ok == result

      assert_received :attempt
      refute_received :attempt
    end

    test "returns timeout error if timeout exceeded" do
      Process.register(self(), __MODULE__)

      assert {:error, :timeout} == Util.wait_until(10, fn -> false end)
    end
  end
end
