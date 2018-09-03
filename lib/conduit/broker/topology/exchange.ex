defmodule Conduit.Broker.Topology.Exchange do
  @moduledoc false

  @type t :: %__MODULE__{
          name: String.t(),
          opts: Keyword.t()
        }
  @type name :: String.t() | (() -> String.t())
  @type opts :: Keyword.t() | (() -> Keyword.t())

  defstruct name: nil, opts: []

  @doc """
  Creates an Exchange struct

  Accepts functions for the arguments, that will be evaluated before returning the struct
  """
  @spec new(name, opts) :: t
  def new(name, opts) do
    %__MODULE__{
      name: name,
      opts: opts
    }
  end

  @doc false
  def escape(%__MODULE__{} = exchange) do
    quote(do: Conduit.Topology.Exchange.new())
    |> put_elem(2, [exchange.name, exchange.opts])
  end
end
