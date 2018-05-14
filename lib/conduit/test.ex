defmodule Conduit.Test do
  @moduledoc """
  Helpers for testing receiving and publishing messages from a message queue.

  The helpers in this module are intended to be used in conjunction
  with the `Conduit.TestAdapter`. When you publish a `Conduit.Message`
  with the `Conduit.TestAdapter` setup, it will send a message to the
  same process that `publish` on your broker, was called in.

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

  @doc false
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
  Asserts that a message was published.

  Same as `Conduit.Test.assert_message_publish/2`, but with timeout
  set to 0.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{})
      assert_message_published(:message)

  """
  defmacro assert_message_published(name) when is_atom(name) do
    quote do: assert_received({:publish, _, unquote(name), _, _, _})
  end

  defmacro assert_message_published(message_pattern) do
    message_code = Macro.to_string(message_pattern)

    quote do
      assert_received({:publish, _, var!(name), unquote(message_pattern), _, _})

      IO.warn("""
      Calling assert_message_published/1 with a message pattern is deprecated. Replace with:

          assert_message_published #{inspect(binding()[:name])}, #{unquote(message_code)}

      Or

          assert_message_published #{inspect(binding()[:name])}
      """)
    end
  end

  @doc """
  Asserts that a message was published.

  Same as `Conduit.Test.assert_message_publish/3`, but with timeout
  set to 0.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{})
      assert_message_published(:message, %Conduit.Message{body: body})
      assert_message_published(:message, message)
      assert_message_published(:message, ^message)

  """
  defmacro assert_message_published(name, message_pattern) when is_atom(name) do
    quote do: assert_received({:publish, _, unquote(name), unquote(message_pattern), _, _})
  end

  defmacro assert_message_published(message_pattern, opts) do
    message_code = Macro.to_string(message_pattern)

    quote do
      assert_received({:publish, _, var!(name), unquote(message_pattern), _, unquote(opts)})

      IO.warn("""
      Calling assert_message_published/2 with a message pattern as the first argument is deprecated. Replace with:

          assert_message_published #{inspect(binding()[:name])}, #{unquote(message_code)}, #{inspect(unquote(opts))}
      """)
    end
  end

  @doc """
  Asserts that a message was published with specific options.

  Same as `Conduit.Test.assert_message_publish/4`, but with timeout
  set to 0.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{}, to: "queue")
      assert_message_published(:message, %Conduit.Message{body: body}, [to: "queue"])
      assert_message_published(:message, message, [to: destination])
      assert_message_published(:message, ^message, ^opts)

  """
  defmacro assert_message_published(name, message_pattern, opts_pattern) when is_atom(name) do
    quote do: assert_received({:publish, _, unquote(name), unquote(message_pattern), _, unquote(opts_pattern)})
  end

  @doc """
  Refutes that a `Conduit.Message` was published.

  Same as `Conduit.Test.refute_message_publish/2`, but with timeout
  set to 0.

  ## Examples

      refute_message_published(:message)
      refute_message_published(_)

  """
  defmacro refute_message_published(name) when is_atom(name) do
    quote do: refute_received({:publish, _, unquote(name), _, _, _})
  end

  defmacro refute_message_published(message_pattern) do
    message_code = Macro.to_string(message_pattern)

    quote do
      refute_received({:publish, _, _, unquote(message_pattern), _, _})

      IO.warn("""
      Calling refute_message_published/1 with a message pattern is deprecated. Replace with:

          refute_message_published :publish_route, #{unquote(message_code)}

      Or

          refute_message_published :publish_route
      """)
    end
  end

  @doc """
  Refutes that a `Conduit.Message` was published.

  Same as `Conduit.Test.refute_message_publish/3`, but with timeout
  set to 0.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{body: "bar"})
      refute_message_published(:message, %Conduit.Message{body: "foo"})

  """
  defmacro refute_message_published(name, message_pattern) when is_atom(name) do
    quote do: refute_received({:publish, _, unquote(name), unquote(message_pattern), _, _})
  end

  defmacro refute_message_published(message_pattern, opts_pattern) do
    message_code = Macro.to_string(message_pattern)
    opts_code = Macro.to_string(opts_pattern)

    quote do
      refute_received({:publish, _, _, unquote(message_pattern), _, unquote(opts_pattern)})

      IO.warn("""
      Calling refute_message_published/2 with a message pattern as the first argument is deprecated. Replace with:

          refute_message_published :publish_route, #{unquote(message_code)}, #{unquote(opts_code)}
      """)
    end
  end

  @doc """
  Refutes that a `Conduit.Message` was published with specific options.

  Same as `Conduit.Test.refute_message_publish/4`, but with timeout
  set to 0.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{body: "bar"}, to: "queue")
      refute_message_published(:message, %Conduit.Message{body: "bar"}, to: "elsewhere")

  """
  defmacro refute_message_published(name, message_pattern, opts_pattern) when is_atom(name) do
    quote do: refute_received({:publish, _, unquote(name), unquote(message_pattern), _, unquote(opts_pattern)})
  end

  @doc """
  Asserts that a `Conduit.Message` will be published.

  Accepts the name of the `route`. `timeout` after 100 ms.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{})
      assert_message_publish(:message)
      assert_message_publish(_)

  """
  defmacro assert_message_publish(name) when is_atom(name) do
    quote do: assert_receive({:publish, _, unquote(name), _, _, _}, 100)
  end

  defmacro assert_message_publish(message_pattern) do
    message_code = Macro.to_string(message_pattern)

    quote do
      assert_receive {:publish, _, var!(name), unquote(message_pattern), _, _}, 100

      IO.warn("""
      Calling assert_message_publish/1 with a message pattern is deprecated. Replace with:

          assert_message_publish #{inspect(binding()[:name])}, #{unquote(message_code)}

      Or

          assert_message_publish #{inspect(binding()[:name])}
      """)
    end
  end

  @doc """
  Asserts that a `Conduit.Message` will be published.

  Accepts the name of the `route` and a pattern for the `message` or a `timeout` for
  how long to wait for the `message`. If a `message` pattern is passed, `timeout` defaults to 100 ms.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{})
      assert_message_publish(:message, 200)
      assert_message_publish(:message, ^message)

  """
  defmacro assert_message_publish(name, timeout) when is_atom(name) and is_integer(timeout) do
    quote do: assert_receive({:publish, _, unquote(name), _, _, _}, unquote(timeout))
  end

  defmacro assert_message_publish(name, message_pattern) when is_atom(name) do
    quote do: assert_receive({:publish, _, unquote(name), unquote(message_pattern), _, _}, 100)
  end

  defmacro assert_message_publish(message_pattern, timeout) when is_integer(timeout) do
    message_code = Macro.to_string(message_pattern)

    quote do
      assert_receive {:publish, _, var!(name), unquote(message_pattern), _, _}, unquote(timeout)

      IO.warn("""
      Calling assert_message_publish/2 with a message pattern as the first argument is deprecated. Replace with:

          assert_message_publish #{inspect(binding()[:name])}, #{unquote(message_code)}, #{unquote(timeout)}

      Or

          assert_message_publish #{inspect(binding()[:name])}, #{unquote(timeout)}
      """)
    end
  end

  @doc """
  Asserts that a `Conduit.Message` will be published.

  Accepts the name of the `route`, a pattern for the `message`, and a pattern for the `options` or a `timeout` for
  how long to wait for the `message`. If a `options` pattern is passed, `timeout` defaults to 100 ms.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{}, to: "here")
      assert_message_publish(:message, %{body: body}, 200)
      assert_message_publish(:message, %{body: body}, [to: "here"])
      assert_message_publish(:message, ^message, 300)

  """
  defmacro assert_message_publish(name, message_pattern, timeout) when is_atom(name) and is_integer(timeout) do
    quote do
      assert_receive {:publish, _, unquote(name), unquote(message_pattern), _, _}, unquote(timeout)
    end
  end

  defmacro assert_message_publish(name, message_pattern, opts_pattern) when is_atom(name) do
    quote do
      assert_receive {:publish, _, unquote(name), unquote(message_pattern), _, unquote(opts_pattern)}, 100
    end
  end

  @doc """
  Asserts that a `Conduit.Message` will be published.

  Accepts the name of the `route`, a pattern for the `message`, a pattern for the `options`, and a `timeout` for
  how long to wait for the `message`.

  ## Examples

      MyApp.Broker.publish(:message, %Conduit.Message{}, to: "here")
      assert_message_publish(:message, %{body: body}, [to: "here"], 200)
      assert_message_publish(:message, message, [to: "here"], 300)
      assert_message_publish(:message, ^message, ^opts, 300)

  """
  defmacro assert_message_publish(name, message_pattern, opts_pattern, timeout)
           when is_atom(name) and is_integer(timeout) do
    quote do
      assert_receive {:publish, _, unquote(name), unquote(message_pattern), _, unquote(opts_pattern)}, unquote(timeout)
    end
  end

  @doc """
  Refutes that a `Conduit.Message` will be published.

  Accepts the name of the `route`. Timeout defaults to `100` ms.

  ## Examples

      refute_message_publish(:message)

  """
  defmacro refute_message_publish(name) when is_atom(name) do
    quote do: refute_receive({:publish, _, unquote(name), _, _, _}, 100)
  end

  defmacro refute_message_publish(message_pattern) do
    message_code = Macro.to_string(message_pattern)

    quote do
      refute_receive({:publish, _, _, unquote(message_pattern), _, _}, 100)

      IO.warn("""
      Calling refute_message_publish/1 with a message pattern as the first argument is deprecated. Replace with:

          refute_message_publish :publish_route, #{unquote(message_code)}

      Or

          refute_message_publish :publish_route
      """)
    end
  end

  @doc """
  Refutes that a `Conduit.Message` will be published.

  Accepts the name of the `route` and a pattern for the `message` or a `timeout` for how long to wait
  for the `message`. If a `message` pattern is passed, timeout defaults to `100` ms.

  ## Examples

      refute_message_publish(:message, 200)
      refute_message_publish(:message, %{body: body})
      refute_message_publish(:message, ^message)

  """
  defmacro refute_message_publish(name, timeout) when is_atom(name) and is_integer(timeout) do
    quote do: refute_receive({:publish, _, unquote(name), _, _, _}, unquote(timeout))
  end

  defmacro refute_message_publish(name, message_pattern) when is_atom(name) do
    quote do: refute_receive({:publish, _, unquote(name), unquote(message_pattern), _, _}, 100)
  end

  defmacro refute_message_publish(message_pattern, timeout) when is_integer(timeout) do
    message_code = Macro.to_string(message_pattern)

    quote do
      refute_receive {:publish, _, _, unquote(message_pattern), _, _}, unquote(timeout)

      IO.warn("""
      Calling refute_message_publish/2 with a message pattern as the first argument is deprecated. Replace with:

          refute_message_publish :publish_route, #{unquote(message_code)}, #{unquote(timeout)}

      Or

          refute_message_publish :publish_route, #{unquote(timeout)}
      """)
    end
  end

  @doc """
  Refutes that a `Conduit.Message` will be published.

  Accepts the name of the `route`, a pattern for the `message`, and a pattern for `options` or a `timeout` for how
  long to wait for the `message`. If a `options` pattern is passed, timeout defaults to `100` ms.

  ## Examples

      refute_message_publish(:message, %Conduit.Message{}, 200)
      refute_message_publish(:message, %{body: body}, [to: "elsewhere"])
      refute_message_publish(:message, ^message, ^options)

  """
  defmacro refute_message_publish(name, message_pattern, timeout) when is_atom(name) and is_integer(timeout) do
    quote do: refute_receive({:publish, _, unquote(name), unquote(message_pattern), _, _}, unquote(timeout))
  end

  defmacro refute_message_publish(name, message_pattern, opts_pattern) when is_atom(name) do
    quote do: refute_receive({:publish, _, unquote(name), unquote(message_pattern), _, unquote(opts_pattern)}, 100)
  end

  @doc """
  Refutes that a `Conduit.Message` will be published.

  Accepts the name of the `route`, a pattern for the `message`, a pattern for `options`, and a `timeout` for how
  long to wait for the `message`.

  ## Examples

      refute_message_publish(:message, %Conduit.Message{}, [to: "elsewhere"], 200)
      refute_message_publish(:message, %{body: body}, [to: "elsewhere"], 10)
      refute_message_publish(:message, ^message, ^options, 50)

  """
  defmacro refute_message_publish(name, message_pattern, opts_pattern, timeout)
           when is_atom(name) and is_integer(timeout) do
    quote do
      refute_receive(
        {:publish, _, unquote(name), unquote(message_pattern), _, unquote(opts_pattern)},
        unquote(timeout)
      )
    end
  end
end
