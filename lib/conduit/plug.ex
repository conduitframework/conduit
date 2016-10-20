defmodule Conduit.Plug do
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app]

      Module.register_attribute(__MODULE__, :plugs, accumulate: :true)

      import Conduit.Plug

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro plug(name, opts \\ []) do
    quote do
      @exchanges {unquote(name), unquote(opts)}
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def plugs, do: @plugs
    end
  end
end
