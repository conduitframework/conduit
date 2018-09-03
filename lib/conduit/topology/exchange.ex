defmodule Conduit.Topology.Exchange do
  @moduledoc """
  Configuration for an exchange
  """
  @type t :: %__MODULE__{
          name: String.t(),
          opts: Keyword.t()
        }
  @type name :: String.t() | (() -> String.t())
  @type opts :: Keyword.t() | (() -> Keyword.t())

  defstruct name: nil, opts: []

  @doc """
  Creates a new Exchange struct

  If functions are passed to either argument, they will be evaluated before returning the struct.

  ## Examples

      iex> Conduit.Topology.Exchange.new("topic")
      %Conduit.Topology.Exchange{name: "topic", opts: []}
      iex> Conduit.Topology.Exchange.new("topic", type: :fanout)
      %Conduit.Topology.Exchange{name: "topic", opts: [type: :fanout]}
      iex> Conduit.Topology.Exchange.new(fn -> "dynamic.name" end, fn -> [type: :fanout] end)
      %Conduit.Topology.Exchange{name: "dynamic.name", opts: [type: :fanout]}
  """
  @spec new(name, opts) :: t()
  def new(name, opts \\ [])
  def new(name, opts) when is_function(name), do: new(name.(), opts)
  def new(name, opts) when is_function(opts), do: new(name, opts.())

  def new(name, opts) when is_binary(name) and is_list(opts) do
    %__MODULE__{name: name, opts: opts}
  end
end
