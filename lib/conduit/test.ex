defmodule Conduit.Test do
  @moduledoc """
  Helpers for testing receiving and publishing messages from a message queue.

  The helpers in this module are intended to be used in conjunction
  with the `Conduit.TestAdapter`. When you publish a `Conduit.Message`
  with the `Conduit.TestAdapter setup, it will send a message to the
  same process that `publish` on your broker, was called in.
  """

  @doc """
  If another process is responsible for publishing a `Conduit.Message`,
  you must:

    1. Pass `[shared: true]` when using `Conduit.Test`
    2. Pass `[async: false]` when using `ExUnit.Case`

  This is necessary, because the helpers and the adapter must share
  configuration to know what the test process is. If `async` is `true`,
  multiple tests could override test process and the `publish`
  notification would go to the wrong process.

  ## Examples

      # Unit Testing
      use ExUnit.Case, async: true
      use Conduit.Test, shared: false

      # Integration Testing
      use ExUnit.Case, async: false
      use Conduit.Test, shared: true

  """
  defmacro __using__(shared: true) do
    quote do
      setup tags do
        if tags[:async] do
          raise """
          You cannot use Conduit.Test shared mode with async tests.
          There are a couple options, the 1st is the easiest:
            1) Set your test to [async: false]. Do this for integration tests,
               where another process is responsible for publishing the message.
            2) Unit test your publish pipelines by calling them directly in your
               tests.
          """
        else
          Application.put_env(:conduit, :shared_test_process, self())
        end

        :ok
      end

      import Conduit.Test, only: :macros
    end
  end
  defmacro __using__(_) do
    quote do
      setup tags do
        Application.delete_env(:conduit, :shared_test_process)

        :ok
      end

      import Conduit.Test
    end
  end

  @doc """
  Asserts that a `Conduit.Message` was published.

  Same as `Conduit.Test.assert_message_publish/2`, but with timeout
  set to 0.

  ## Examples

      assert_message_published(%{body: body})
      assert_message_published(^message)

  """
  defmacro assert_message_published(message) do
    quote do: assert_received {:publish, unquote(message), _, _}
  end

  @doc """
  Asserts that a `Conduit.Message` was published with specific options.

  Same as `Conduit.Test.assert_message_publish/3`, but with timeout
  set to 0.

  ## Examples

      assert_message_published(%{body: body}, [to: to])
      assert_message_published(^message, ^opts)

  """
  defmacro assert_message_published(message, opts) do
    quote do: assert_received {:publish, unquote(message), _, unquote(opts)}
  end

  @doc """
  Refutes that a `Conduit.Message` was published.

  Same as `Conduit.Test.refute_message_publish/2`, but with timeout
  set to 0.

  ## Examples

      refute_message_published(^message)
      refute_message_published(_)

  """
  defmacro refute_message_published(message) do
    quote do: refute_received {:publish, unquote(message), _, _}
  end

  @doc """
  Refutes that a `Conduit.Message` was published with specific options.

  Same as `Conduit.Test.refute_message_publish/3`, but with timeout
  set to 0.

  ## Examples

      refute_message_published(^message, ^opts)
      refute_message_published(_, _)

  """
  defmacro refute_message_published(message, opts) do
    quote do: refute_received {:publish, unquote(message), _, unquote(opts)}
  end

  @doc """
  Asserts that a `Conduit.Message` will be published.

  Accepts a pattern for the `message` and a `timeout` for how long to wait
  for the `message`. Timeout defaults to `100` ms.

  ## Examples

      assert_message_publish(%{body: body})
      assert_message_publish(^message)

  """
  defmacro assert_message_publish(message, timeout \\ 100) when is_integer(timeout) do
    quote do: assert_receive {:publish, unquote(message), _, _}, unquote(timeout)
  end

  @doc """
  Refutes that a `Conduit.Message` will be published.

  Accepts a pattern for the `message` and a `timeout` for how long to wait
  for the `message`. Timeout defaults to `100` ms.

  ## Examples

      refute_message_publish(%{body: body})
      refute_message_publish(^message)

  """
  defmacro refute_message_publish(message, timeout \\ 100) when is_integer(timeout) do
    quote do: refute_receive {:publish, unquote(message), _, _}, unquote(timeout)
  end
end
