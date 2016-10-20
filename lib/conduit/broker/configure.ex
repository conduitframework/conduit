defmodule Conduit.Broker.Configure do
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app]

      Module.register_attribute(__MODULE__, :exchanges, accumulate: :true)
      Module.register_attribute(__MODULE__, :queues, accumulate: :true)

      import Conduit.Broker.Configure

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro exchange(name, opts \\ []) do
    quote do
      @exchanges {unquote(name), unquote(opts)}
    end
  end

  defmacro queue(name, opts \\ []) do
    quote do
      @queues {unquote(name), unquote(opts)}
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @ordered_exchanges @exchanges |> Enum.reverse
      def exchanges, do: @ordered_exchanges

      @ordered_queues @queues |> Enum.reverse
      def queues, do: @ordered_queues
    end
  end
end
