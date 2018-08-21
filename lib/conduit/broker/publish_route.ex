defmodule Conduit.Broker.PublishRoute do
  @moduledoc false

  @type name :: atom
  @type opts :: Keyword.t()
  @type pipelines :: [module]
  @type t :: %__MODULE__{
          name: name,
          opts: opts,
          pipelines: pipelines
        }

  defstruct name: nil, opts: [], pipelines: []

  @doc """
  Creates a new PublishRoute struct
  """
  @spec new(name, opts, pipelines) :: t
  def new(name, opts, pipelines \\ []) do
    %__MODULE__{
      name: name,
      opts: opts,
      pipelines: pipelines
    }
  end

  @doc """
  Updates the pipeline property
  """
  @spec put_pipelines(t, pipelines) :: t
  def put_pipelines(%__MODULE__{} = route, pipelines) do
    %{route | pipelines: pipelines}
  end

  def escape(%__MODULE__{} = route) do
    quote(do: Conduit.PublishRoute.new())
    |> put_elem(2, [route.name, route.pipelines, route.opts])
  end
end
