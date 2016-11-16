defmodule Conduit.Broker.Configure do
  @moduledoc false

  @doc false
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :setup, accumulate: :true)

      import Conduit.Broker.Configure

      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Defines an exchange to setup.
  """
  defmacro exchange(name, opts \\ []) do
    quote do
      @setup {:exchange, unquote(name), unquote(opts)}
    end
  end

  @doc """
  Defines a queue to setup.
  """
  defmacro queue(name, opts \\ []) do
    quote do
      @setup {:queue, unquote(name), unquote(opts)}
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      @ordered_setup @setup |> Enum.reverse
      def setup, do: @ordered_setup
    end
  end
end
