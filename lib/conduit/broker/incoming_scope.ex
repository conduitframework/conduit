defmodule Conduit.Broker.IncomingScope do
  @moduledoc false
  import Conduit.Broker.Scope
  alias Conduit.Broker.SubscribeRoute

  defstruct pipelines: [], subscribe_routes: [], namespace: nil

  @doc """
  Initializes the incoming scope for subscribers.
  """
  @spec init(module) :: :ok
  def init(module) do
    Module.register_attribute(module, :subscribe_routes, accumulate: true)
    put_scope(module, nil)
  end

  @doc """
  Starts a scope block.
  """
  @spec start_scope(module, module) :: :ok | no_return
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
  @spec end_scope(module) :: :ok
  def end_scope(module) do
    scope = get_scope(module)

    scope.subscribe_routes
    |> Enum.map(&SubscribeRoute.expand_subscriber(&1, scope.namespace))
    |> Enum.map(&SubscribeRoute.put_pipelines(&1, scope.pipelines))
    |> Enum.each(fn route ->
      Module.put_attribute(module, :subscribe_routes, route)
    end)

    put_scope(module, nil)
  end

  @doc """
  Sets the pipelines for the scope.
  """
  @spec pipe_through(module, [atom]) :: :ok
  def pipe_through(module, pipelines) do
    put_scope(module, %{get_scope(module) | pipelines: List.wrap(pipelines)})
  end

  @doc """
  Defines a subscriber for the block.
  """
  @spec subscribe(module, atom, module, Keyword.t()) :: :ok | no_return
  def subscribe(module, name, subscriber, opts) do
    if scope = get_scope(module) do
      sub = SubscribeRoute.new(name, subscriber, opts)
      put_scope(module, %{scope | subscribe_routes: [sub | scope.subscribe_routes]})
    else
      raise Conduit.BrokerDefinitionError, "subscribe can only be called under an incoming block"
    end
  end

  @doc """
  Generates the body of receives for a specific route
  """
  def compile(route) do
    source = Keyword.get(route.opts, :from, Atom.to_string(route.name))

    pipeline_plugs =
      route.pipelines
      |> Enum.map(&{:pipeline, &1})
      |> Enum.reverse()

    plugs = [{route.subscriber, route.opts} | pipeline_plugs] ++ [{:put_new_source, source}]
    Conduit.Plug.Builder.compile(plugs, quote(do: & &1))
  end

  @doc """
  Defines subscriber related methods for the broker.
  """
  @spec methods(module) :: term | no_return
  def methods(module) do
    validate_routes!(module)

    quote unquote: false do
      subscribe_routes = Enum.map(@subscribe_routes, &Conduit.Broker.SubscribeRoute.escape/1)
      def subscribe_routes, do: unquote(subscribe_routes)

      for route <- @subscribe_routes do
        pipeline = Conduit.Broker.IncomingScope.compile(route)

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

  defp validate_routes!(module) do
    module
    |> Module.get_attribute(:subscribe_routes)
    |> Enum.group_by(& &1.name)
    |> Enum.each(fn
      {route_name, routes} when length(routes) > 1 ->
        raise Conduit.DuplicateRouteError, """
        Duplicate subscribe route named #{inspect(route_name)} found in #{inspect(module)}.

        Subscribe route names must be unique, because they are used to route messages through the correct
        pipelines and to the right subscriber.
        """

      _ ->
        nil
    end)
  end
end
