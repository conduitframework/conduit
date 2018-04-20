defmodule Conduit.Broker.IncomingScope do
  @moduledoc false
  import Conduit.Broker.Scope

  defstruct pipelines: [], subscribers: [], namespace: nil

  @doc """
  Initializes the incoming scope for subscribers.
  """
  def init(module) do
    Module.register_attribute(module, :subscriber_configs, accumulate: true)
    Module.register_attribute(module, :subscribers, accumulate: true)
    put_scope(module, nil)
  end

  @doc """
  Starts a scope block.
  """
  def start_scope(module, namespace) do
    if get_scope(module) do
      raise Conduit.BrokerDefinitionError, "incoming cannot be nested under anything else"
    else
      put_scope(module, %__MODULE__{namespace: namespace})
    end
  end

  @doc """
  Ends a scope block.
  """
  def end_scope(module) do
    scope = get_scope(module)

    Enum.each(scope.subscribers, fn {name, subscriber, opts} ->
      subscriber_name = Module.concat(scope.namespace, subscriber)

      Module.put_attribute(
        module,
        :subscriber_configs,
        {name, subscriber_name, scope.pipelines, opts}
      )
    end)

    put_scope(module, nil)
  end

  @doc """
  Sets the pipelines for the scope.
  """
  def pipe_through(module, pipelines) do
    put_scope(module, %{get_scope(module) | pipelines: pipelines})
  end

  @doc """
  Defines a subscriber for the block.
  """
  def subscribe(module, name, subscriber, opts) do
    if scope = get_scope(module) do
      sub = {name, subscriber, opts}
      put_scope(module, %{scope | subscribers: [sub | scope.subscribers]})
    else
      raise Conduit.BrokerDefinitionError, "subscribe can only be called under an incoming block"
    end
  end

  @doc """
  Compiles the subscribers.
  """
  def compile(module) do
    module
    |> Module.get_attribute(:subscriber_configs)
    |> Enum.each(fn {name, subscriber, pipeline_names, opts} ->
      mod = generate_module(module, name, "_incoming")
      expanded_pipelines = expand_pipelines(module, pipeline_names)
      source = Keyword.get(opts, :from, Atom.to_string(name))

      defmodule mod do
        @moduledoc false
        use Conduit.Plug.Builder

        plug :put_source, source

        Enum.each(expanded_pipelines, fn pipeline ->
          plug pipeline
        end)

        defdelegate call(message, next, opts), to: subscriber
      end

      Module.put_attribute(module, :subscribers, {name, {mod, opts}})
    end)
  end

  @doc """
  Defines subscriber related methods for the broker.
  """
  def methods do
    quote unquote: false do
      @subscribers_map Enum.into(@subscribers, %{})
      def subscribers, do: @subscribers_map

      for {name, {subscriber, opts}} <- @subscribers_map do
        def receives(unquote(name), message) do
          unquote(subscriber).run(message, unquote(opts))
        end
      end

      def receives(name, _) do
        message = """
        Undefined subscribe route #{inspect(name)}.

        Perhaps #{inspect(name)} is misspelled. Otherwise, it can be defined in #{inspect(__MODULE__)} by adding:

            incoming MyApp do
              subscribe #{inspect(name)}, MySubscriber, from: "my.source", other: "options"
            end
        """

        raise Conduit.UndefinedSubscribeRouteError, message
      end
    end
  end
end
