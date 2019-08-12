defmodule Conduit.Broker.OutgoingScope do
  @moduledoc false
  import Conduit.Broker.Scope
  alias Conduit.Broker.PublishRoute

  defstruct pipelines: [], publish_routes: []

  @doc """
  Initializes outgoing scope for publishers.
  """
  @spec init(module) :: :ok
  def init(broker) do
    Module.register_attribute(broker, :publish_routes, accumulate: true)
    put_scope(broker, nil)
  end

  @doc false
  @spec start_scope(module) :: :ok
  def start_scope(broker) do
    if get_scope(broker) do
      raise Conduit.BrokerDefinitionError, "outgoing cannot be nested under anything else"
    else
      put_scope(broker, %__MODULE__{})
    end
  end

  @doc """
  Sets the pipelines for the scope.
  """
  @spec pipe_through(module, [atom]) :: :ok
  def pipe_through(broker, pipelines) do
    put_scope(broker, %{get_scope(broker) | pipelines: List.wrap(pipelines)})
  end

  @doc """
  Defines a publisher.
  """
  @spec publish(module, atom, Keyword.t()) :: :ok | no_return
  def publish(broker, name, opts) do
    if scope = get_scope(broker) do
      route = PublishRoute.new(name, opts)
      put_scope(broker, %{scope | publish_routes: [route | scope.publish_routes]})
    else
      raise Conduit.BrokerDefinitionError, "publish can only be called under an outgoing block"
    end
  end

  @doc """
  Ends a scope block.
  """
  @spec end_scope(module) :: :ok
  def end_scope(broker) do
    scope = get_scope(broker)

    scope.publish_routes
    |> Enum.map(&PublishRoute.put_pipelines(&1, scope.pipelines))
    |> Enum.each(&Module.put_attribute(broker, :publish_routes, &1))

    put_scope(broker, nil)
  end

  @doc """
  Generates the body of receives for a specific route
  """
  def compile(broker, route) do
    destination = Keyword.get(route.opts, :to, Atom.to_string(route.name))

    pipeline_plugs =
      route.pipelines
      |> Enum.map(&{:pipeline, &1})
      |> Enum.reverse()

    plugs =
      [{:raw_publish, route.opts} | pipeline_plugs] ++
        [
          {:put_private, broker: broker, received: route.name},
          {:put_new_destination, destination}
        ]

    Conduit.Plug.Builder.compile(plugs, quote(do: & &1))
  end

  defmacro defpublish_routes() do
    module = __CALLER__.module
    validate_routes!(module)

    publish_routes =
      module
      |> Module.get_attribute(:publish_routes)
      |> Enum.map(&Conduit.Broker.PublishRoute.escape(&1, __MODULE__))

    quote location: :keep do
      def publish_routes(config) do
        unquote(publish_routes)
      end
    end
  end

  defmacro defpublish() do
    publish_with_default = quote(do: def(publish(message, name, opts \\ [])))

    deprecated_publish =
      quote location: :keep do
        def publish(name, message, opts) when is_atom(name) do
          require Logger

          warning = """
          Calling #{inspect(__MODULE__)}.publish/3 with message as second argument is deprecated to enable pipeline usage.

          Replace:

              #{inspect(__MODULE__)}.publish(#{inspect(name)}, message, opts)

          With:

              #{inspect(__MODULE__)}.publish(message, #{inspect(name)}, opts)
          """

          Logger.warn(warning)
          publish(message, name, opts)
        end
      end

    module = __CALLER__.module

    publishes =
      for route <- Module.get_attribute(module, :publish_routes),
          pipeline = Conduit.Broker.OutgoingScope.compile(module, route) do
        quote location: :keep do
          def publish(message, unquote(route.name), opts) do
            config = Conduit.Broker.get_config(__MODULE__, opts)

            message
            |> Conduit.Message.put_private(:opts, opts)
            |> Conduit.Message.put_private(:broker_config, config)
            |> unquote(pipeline).()
          end
        end
      end

    fallback_publish =
      quote location: :keep do
        def publish(_, name, _) do
          message = """
          Undefined publish route #{inspect(name)}.

          Perhaps #{inspect(name)} is misspelled. Otherwise, it can be defined in #{inspect(__MODULE__)} by adding:

              outgoing do
                publish #{inspect(name)}, to: "my.destination", other: "options"
              end
          """

          raise Conduit.UndefinedPublishRouteError, message
        end
      end

    [publish_with_default, deprecated_publish | publishes] ++ [fallback_publish]
  end

  defmacro defraw_publish do
    quote location: :keep do
      @doc false
      def raw_publish(message, _next, opts) do
        Conduit.Broker.raw_publish(__MODULE__, message, opts)
      end
    end
  end

  defp validate_routes!(module) do
    module
    |> Module.get_attribute(:publish_routes)
    |> Enum.group_by(& &1.name)
    |> Enum.each(fn
      {route_name, routes} when length(routes) > 1 ->
        raise Conduit.DuplicateRouteError, """
        Duplicate publish route named #{inspect(route_name)} found in #{inspect(module)}.

        Publish route names must be unique, because they are used to route messages through the correct
        pipelines and send to the right queue.
        """

      _ ->
        nil
    end)
  end
end
