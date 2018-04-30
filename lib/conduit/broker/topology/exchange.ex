defmodule Conduit.Broker.Topology.Exchange do
  @moduledoc """
  Configuration for an exchange
  """

  @type t :: %__MODULE__{
    name: String.t,
    opts: Keyword.t
  }
  @type name :: String.t | (() -> String.t)
  @type opts :: Keyword.t | (() -> Keyword.t)

  defstruct name: nil, opts: []

  @doc """
  Creates an Exchange struct

  Accepts functions for the arguments, that will be evaluated before returning the struct
  """
  @spec new(name, opts) :: t
  def new(name, opts) when is_function(name), do: new(name.(), opts)
  def new(name, opts) when is_function(opts), do: new(name, opts.())

  def new(name, opts) do
    %__MODULE__{
      name: name,
      opts: opts
    }
  end

  @doc false
  @spec to_tuple(queue :: t) :: {:exchange, String.t, Keyword.t}
  def to_tuple(%__MODULE__{} = data) do
    {:exchange, data.name, data.opts}
  end
end
