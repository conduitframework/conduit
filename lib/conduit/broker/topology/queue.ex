defmodule Conduit.Broker.Topology.Queue do
  @moduledoc false
  @type t :: %__MODULE__{
          name: String.t(),
          opts: Keyword.t()
        }
  @type name :: String.t()
  @type opts :: Keyword.t()

  defstruct name: nil, opts: []

  @spec new(name, opts) :: t()
  def new(name, opts) do
    %__MODULE__{
      name: name,
      opts: opts
    }
  end

  @doc false
  # Conduit.Topology.Queue.new(name, opts)
  def escape(%__MODULE__{} = queue) do
    quote(do: Conduit.Topology.Queue.new())
    |> put_elem(2, [queue.name, queue.opts])
  end
end
