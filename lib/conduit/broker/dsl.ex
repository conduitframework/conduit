defmodule Conduit.Broker.DSL do
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise "endpoint expects :otp_app to be given"
      @configure nil

      Module.register_attribute(__MODULE__, :pipelines, accumulate: :true)
      import Conduit.Broker.DSL

      Conduit.Broker.IncomingScope.init(__MODULE__)
      Conduit.Broker.OutgoingScope.init(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro configure(do: block) do
    quote do
      defmodule Configure do
        use Conduit.Broker.Configure

        unquote(block)
      end
      @configure __MODULE__.Configure
    end
  end

  defmacro pipeline(name, do: block) do
    quote do
      module = Conduit.Broker.Scope.generate_module(__MODULE__, unquote(name), "_pipeline")
      @pipelines {unquote(name), module}

      defmodule module do
        use Conduit.Plug.Builder

        unquote(block)
      end
    end
  end

  defmacro incoming(namespace, do: block) do
    quote do
      Conduit.Broker.IncomingScope.start_scope(__MODULE__, unquote(namespace))

      unquote(block)

      Conduit.Broker.IncomingScope.end_scope(__MODULE__)
    end
  end

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

  defmacro sub(name, subscriber, opts \\ []) do
    quote do
      Conduit.Broker.IncomingScope.subscribe(__MODULE__, unquote(name), unquote(subscriber), unquote(opts))
    end
  end

  defmacro outgoing(do: block) do
    quote do
      Conduit.Broker.OutgoingScope.start_scope(__MODULE__)

      unquote(block)

      Conduit.Broker.OutgoingScope.end_scope(__MODULE__)
    end
  end

  defmacro pub(name, opts \\ []) do
    quote do
      Conduit.Broker.OutgoingScope.publish(__MODULE__, unquote(name), unquote(opts))
    end
  end

  defmacro __before_compile__(_) do
    quote do
      if @configure do
        def exchanges, do: @configure.exchanges
        def queues, do: @configure.queues
      else
        def exchanges, do: []
        def queues, do: []
      end

      def pipelines, do: @pipelines

      Conduit.Broker.IncomingScope.compile(__MODULE__)
      Conduit.Broker.OutgoingScope.compile(__MODULE__)

      unquote(Conduit.Broker.IncomingScope.methods)
      unquote(Conduit.Broker.OutgoingScope.methods)
    end
  end
end
