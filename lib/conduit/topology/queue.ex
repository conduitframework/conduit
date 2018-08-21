defmodule Conduit.Topology.Queue do
  @moduledoc """
  Configuration for an queue
  """
  @type t :: %__MODULE__{
          name: String.t(),
          opts: Keyword.t()
        }
  @type name :: String.t() | (() -> String.t())
  @type opts :: Keyword.t() | (() -> Keyword.t())

  defstruct name: nil, opts: []

  @doc """
  Creates a new Queue struct

  If functions are passed to either argument, they will be evaluated before returning the struct.

  ## Examples

    iex> Conduit.Topology.Queue.new("my_app.event")
    %Conduit.Topology.Queue{name: "my_app.event", opts: []}
    iex> Conduit.Topology.Queue.new("my_app.event", from: ["my_app.event_queue"])
    %Conduit.Topology.Queue{name: "my_app.event", opts: [from: ["my_app.event_queue"]]}
    iex> Conduit.Topology.Queue.new(fn -> "dynamic.name" end, fn -> [from: ["my_app.event_queue"]] end)
    %Conduit.Topology.Queue{name: "dynamic.name", opts: [from: ["my_app.event_queue"]]}
  """
  @spec new(name, opts) :: t()
  def new(name, opts \\ [])
  def new(name, opts) when is_function(name), do: new(name.(), opts)
  def new(name, opts) when is_function(opts), do: new(name, opts.())

  def new(name, opts) when is_binary(name) and is_list(opts) do
    %__MODULE__{name: name, opts: opts}
  end
end
