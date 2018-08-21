defmodule Conduit.Broker.SubscribeRoute do
  @moduledoc false

  @type name :: atom
  @type subscriber :: module
  @type opts :: Keyword.t()
  @type pipelines :: [Conduit.Broker.Pipeline.t() | atom]
  @type t :: %__MODULE__{
          name: String.t(),
          subscriber: module,
          opts: Keyword.t(),
          pipelines: pipelines
        }

  defstruct name: nil, subscriber: nil, opts: [], pipelines: []

  @doc """
  Creates a new SubscribeRoute struct
  """
  @spec new(name, subscriber, opts, pipelines) :: t
  def new(name, subscriber, opts, pipelines \\ []) do
    %__MODULE__{
      name: name,
      subscriber: subscriber,
      opts: opts,
      pipelines: pipelines
    }
  end

  @doc false
  @spec expand_subscriber(t, module) :: t
  def expand_subscriber(%__MODULE__{} = route, namespace) do
    %{route | subscriber: Module.concat(namespace, route.subscriber)}
  end

  @doc """
  Updates the pipeline property
  """
  @spec put_pipelines(t, pipelines) :: t
  def put_pipelines(%__MODULE__{} = route, pipelines) do
    %{route | pipelines: pipelines}
  end

  def escape(%__MODULE__{} = route) do
    quote(do: Conduit.SubscribeRoute.new())
    |> put_elem(2, [route.name, Macro.escape(route.subscriber), route.pipelines, route.opts])
  end
end
