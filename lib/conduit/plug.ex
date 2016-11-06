defmodule Conduit.Plug do
  @type opts :: tuple | atom | integer | float | [opts]

  @callback init(opts) :: opts
  @callback call(Conduit.Message.t, opts) :: Conduit.Message.t

  defmacro __using__(_) do
    quote do
      @behaviour Conduit.Plug

      def init(opts), do: opts

      defoverridable [init: 1]
    end
  end
end
