defmodule Conduit.Broker do
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise "endpoint expects :otp_app to be given"
      @configure nil
      @incoming_namespace nil
      @pipe_through nil
      @outgoing nil
      @consume nil
      @publish nil

      Module.register_attribute(__MODULE__, :pipelines, accumulate: :true)
      Module.register_attribute(__MODULE__, :consumers, accumulate: :true)
      Module.register_attribute(__MODULE__, :publishers, accumulate: :true)

      import Conduit.Broker

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
    module_name =
      name
      |> Atom.to_string
      |> Kernel.<>("_pipeline")
      |> Macro.camelize

    quote do
      module = Module.concat(__MODULE__, unquote(module_name))
      @pipelines {unquote(name), module}

      defmodule module do
        use Conduit.Plug

        unquote(block)
      end
    end
  end

  defmacro incoming(namespace, do: block) do
    quote do
      @incoming_namespace unquote(namespace)

      unquote(block)

      @pipe_through nil
      @consume nil
      @incoming_namespace nil
    end
  end

  defmacro pipe_through(pipelines) do
    pipelines = List.wrap(pipelines)

    quote do
      cond do
        !@incoming_namespace && !@outgoing ->
          raise "pipe_through must be within an incoming or outgoing block"
        @consume ->
          raise "pipe_through must be defined before consume"
        @publish ->
          raise "pipe_through must be defined before publish"
        true ->
          @pipe_through unquote(pipelines)
      end
    end
  end

  defmacro consume(queue, consumer, opts \\ []) do
    quote do
      if @incoming_namespace do
        @consumers {
          unquote(queue),
          @pipe_through,
          Module.concat(@incoming_namespace, unquote(consumer)),
          unquote(opts)
        }
        @consume true
      else
        raise "consume must be within an incoming block"
      end
    end
  end

  defmacro outgoing(do: block) do
    quote do
      unless @incoming_namespace do
        @outgoing true

        unquote(block)

        @pipe_through nil
        @publish nil
        @outgoing nil
      else
        raise "outgoing cannot be nested in an incoming block"
      end
    end
  end

  defmacro publish(name, opts \\ []) do
    quote do
      if @outgoing do
        @publishers {
          unquote(name),
          @pipe_through,
          unquote(opts)
        }
        @publish true
      else
        raise "publish must be withing an outgoing block"
      end
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
      def pipelines(names) do
        names = List.wrap(names)
        pipelines |> Keyword.take(names)
      end

      def consumers, do: @consumers
      def publishers, do: @publishers
    end
  end
end
