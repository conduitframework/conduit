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
  @type config :: Keyword.t()

  defstruct name: nil, opts: []

  @doc """
  Creates a new Exchange struct

  If functions are passed to either argument, they will be evaluated before returning the struct.

  ## Examples

      iex> Conduit.Topology.Exchange.new("topic", [type: :fanout], [])
      %Conduit.Topology.Exchange{name: "topic", opts: [type: :fanout]}
      iex> Conduit.Topology.Exchange.new(fn -> "dynamic.name" end, fn -> [type: :fanout] end, [])
      %Conduit.Topology.Exchange{name: "dynamic.name", opts: [type: :fanout]}
      iex> config = [name: "dynamic.name", opts: [type: :fanout]]
      iex> Conduit.Topology.Exchange.new(fn config -> config[:name] end, fn config -> config[:opts] end, config)
      %Conduit.Topology.Exchange{name: "dynamic.name", opts: [type: :fanout]}
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
    raise Conduit.BadArityError,
          "Exchange declared with function that has invalidy arity. Expected 0 or 1, got #{arity}"
  end
end
