defmodule Conduit.Broker.DSL do
  @moduledoc """
  Provides macros for setting up a message broker, subscribing to queues,
  publishing messages, and pipelines for processing messages.
  """

  alias Conduit.Broker.{DSL, Scope, IncomingScope, OutgoingScope}

  @doc false
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app]
      @configure nil

      Module.register_attribute(__MODULE__, :pipelines, accumulate: true)
      import DSL

      IncomingScope.init(__MODULE__)
      OutgoingScope.init(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Defines configuration of a message queue.
  """
  defmacro configure(do: block) do
    quote do
      defmodule Configure do
        @moduledoc false
        use Conduit.Broker.Configure

        unquote(block)
      end

      @configure __MODULE__.Configure
    end
  end

  @doc """
  Defines a message pipeline.
  """
  defmacro pipeline(name, do: block) do
    quote do
      module = Scope.generate_module(__MODULE__, unquote(name), "_pipeline")
      @pipelines {unquote(name), module}

      defmodule module do
        @moduledoc false
        use Conduit.Plug.Builder

        unquote(block)
      end
    end
  end

  @doc """
  Defines a grouped of subscribers who share the same pipelines.
  """
  defmacro incoming(namespace, do: block) do
    quote do
      IncomingScope.start_scope(__MODULE__, unquote(namespace))

      unquote(block)

      IncomingScope.end_scope(__MODULE__)
    end
  end

  @doc """
  Defines a set of pipelines for the surrounding scope.
  """
  defmacro pipe_through(pipelines) do
    pipelines = List.wrap(pipelines)

    quote do
      if @scope do
        @scope.__struct__.pipe_through(__MODULE__, unquote(pipelines))
      else
        raise "pipe_through can only be called in an incoming or outgoing block"
      end
    end
  end

  @doc """
  Defines a subscriber.
  """
  defmacro subscribe(name, subscriber, opts \\ []) do
    quote do
      IncomingScope.subscribe(__MODULE__, unquote(name), unquote(subscriber), unquote(opts))
    end
  end

  @doc """
  Defines a group of outgoing message publications that share a set of pipelines.
  """
  defmacro outgoing(do: block) do
    quote do
      OutgoingScope.start_scope(__MODULE__)

      unquote(block)

      OutgoingScope.end_scope(__MODULE__)
    end
  end

  @doc """
  Defines a publisher.
  """
  defmacro publish(name, opts \\ []) do
    quote do
      OutgoingScope.publish(__MODULE__, unquote(name), unquote(opts))
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      if @configure do
        def topology, do: @configure.topology
      else
        def topology, do: []
      end

      def pipelines, do: @pipelines

      unquote(IncomingScope.methods())
      unquote(OutgoingScope.methods())
    end
  end
end
