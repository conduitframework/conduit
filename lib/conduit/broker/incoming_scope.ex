defmodule Conduit.Broker.IncomingScope do
  @moduledoc false
  import Conduit.Broker.Scope
  alias Conduit.SubscribeRoute

  defstruct pipelines: [], subscriber_routes: [], namespace: nil

  @doc """
  Initializes the incoming scope for subscribers.
  """
  def init(module) do
    Module.register_attribute(module, :subscriber_routes, accumulate: true)
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

    Enum.each(scope.subscriber_routes, fn subscriber_route ->
      Module.put_attribute(
        module,
        :subscriber_routes,
        SubscribeRoute.extend(subscriber_route, scope.namespace, expand_pipelines(module, scope.pipelines))
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
      sub = SubscribeRoute.new(name, subscriber, opts)
      put_scope(module, %{scope | subscriber_routes: [sub | scope.subscriber_routes]})
    else
      raise Conduit.BrokerDefinitionError, "subscribe can only be called under an incoming block"
    end
  end

  @doc """
  Defines subscriber related methods for the broker.
  """
  def methods do
    quote unquote: false do
      def subscriber_routes, do: @subscriber_routes

      @subscribers_map Enum.reduce(@subscriber_routes, %{}, fn route, acc ->
        Map.put(acc, route.name, {route.subscriber, route.opts})
      end)
      def subscribers, do: @subscribers_map

      import Conduit.Plug.MessageActions, only: [put_source: 3]
      for route <- @subscriber_routes do
        source = Keyword.get(route.opts, :from, Atom.to_string(route.name))
        pipelines = Enum.map(route.pipelines, &({&1, []}))
        plugs = [{route.subscriber, route.opts} | pipelines] ++ [{:put_source, source}]
        pipeline = Conduit.Plug.Builder.compile(plugs, quote do: & &1)

        def receives(unquote(route.name), message) do
          unquote(pipeline).(message)
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
