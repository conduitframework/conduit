defmodule Conduit.Broker.Configure do
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :setup, accumulate: :true)

      import Conduit.Broker.Configure

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro exchange(name, opts \\ []) do
    quote do
      @setup {:exchange, unquote(name), unquote(opts)}
    end
  end

  defmacro queue(name, opts \\ []) do
    quote do
      @setup {:queue, unquote(name), unquote(opts)}
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @ordered_setup @setup |> Enum.reverse
      def setup, do: @ordered_setup
    end
  end
end
