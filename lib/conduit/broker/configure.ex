defmodule Conduit.Broker.Configure do
  @moduledoc false

  @doc false
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :topology, accumulate: :true)

      import Conduit.Broker.Configure

      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Defines an exchange to setup.
  """
  defmacro exchange(name, opts \\ []) do
    quote do
      @topology {:exchange, unquote(name), unquote(opts)}
    end
  end

  @doc """
  Defines a queue to setup.
  """
  defmacro queue(name, opts \\ []) do
    quote do
      @topology {:queue, unquote(name), unquote(opts)}
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      @ordered_topology @topology |> Enum.reverse
      def topology, do: @ordered_topology
    end
  end
end
