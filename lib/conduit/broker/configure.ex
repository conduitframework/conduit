defmodule Conduit.Broker.Configure do
  @moduledoc """
  Provides macros to define the messaage queue topology.

  Within your broker, you can configure the topology of
  your message queue. Not every macro or options will apply
  to all message queues.

  ## Examples

      defmodule MyApp.Broker do
        use Conduit.Broker, otp_app: :my_app

        configure do
          exchange "my.topic"

          queue "my.queue", from: ["every.where"], exchange: "my.topic"
          queue "your.queue", from: ["else.where"], exchange: "my.topic"
        end
      end

  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :topology, accumulate: :true)

      import Conduit.Broker.Configure

      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Defines an exchange to setup.
  """
  defmacro exchange(name, opts \\ [])
  defmacro exchange({:fn, _, _} = fun, opts) do
    quote bind_quoted: [name: :erlang.term_to_binary(fun), opts: opts] do
      @topology {:exchange, {:fun, name}, opts}
    end
  end
  defmacro exchange(name, opts) do
    quote bind_quoted: [name: name, opts: opts] do
      @topology {:exchange, name, opts}
    end
  end

  @doc """
  Defines a queue to setup.
  """
  defmacro queue(name, opts \\ [])
  defmacro queue({:fn, _, _} = fun, opts) do
    quote bind_quoted: [name: :erlang.term_to_binary(fun), opts: opts] do
      @topology {:queue, {:fun, name}, opts}
    end
  end
  defmacro queue(name, opts) do
    quote bind_quoted: [name: name, opts: opts] do
      @topology {:queue, name, opts}
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote unquote: false do
      ordered_topology =
        @topology
        |> Enum.reverse()
        |> Enum.map(fn
          {type, {:fun, binary}, opts} ->
            {:{}, [], [type, :erlang.binary_to_term(binary), opts]}
          item ->
            Macro.escape(item)
        end)

      def topology do
        Enum.map(unquote(ordered_topology), fn
          {type, name, opts} when is_function(name) ->
            {type, name.(), opts}
          item ->
            item
        end)
      end
    end
  end
end
