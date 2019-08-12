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
  @type config :: Keyword.t()

  defstruct name: nil, opts: []

  @doc """
  Creates a new Queue struct

  If functions are passed to either argument, they will be evaluated before returning the struct.

  ## Examples

    iex> Conduit.Topology.Queue.new(
    iex>   "my_app.event",
    iex>   [from: ["my_app.event_queue"]],
    iex>   [])
    %Conduit.Topology.Queue{name: "my_app.event", opts: [from: ["my_app.event_queue"]]}
    iex> Conduit.Topology.Queue.new(
    iex>   fn -> "dynamic.name" end,
    iex>   fn -> [from: ["my_app.event_queue"]] end,
    iex>   [])
    %Conduit.Topology.Queue{name: "dynamic.name", opts: [from: ["my_app.event_queue"]]}
    iex> config = [name: "dynamic.name", opts: [from: ["my_app.event_queue"]]]
    iex> Conduit.Topology.Queue.new(
    iex>   fn config -> config[:name] end,
    iex>   fn -> config[:opts] end,
    iex>   config)
    %Conduit.Topology.Queue{name: "dynamic.name", opts: [from: ["my_app.event_queue"]]}
  """
  @spec new(name, opts, config) :: t()
  def new(name, opts, config) when is_function(name), do: new(eval(name, config), opts, config)
  def new(name, opts, config) when is_function(opts), do: new(name, eval(opts, config), config)

  def new(name, opts, _config) when is_binary(name) and is_list(opts) do
    %__MODULE__{name: name, opts: opts}
  end

  defp eval(fun, config), do: eval(:erlang.fun_info(fun, :arity), fun, config)

  defp eval({:arity, 0}, fun, _config), do: fun.()
  defp eval({:arity, 1}, fun, config), do: fun.(config)

  defp eval({:arity, arity}, _fun, _config) do
    raise Conduit.BadArityError, "Queue declared with function that has invalidy arity. Expected 0 or 1, got #{arity}"
  end
end
