defmodule Conduit.Subscriber do
  defmacro __using__ do
    quote do
      @behavior Conduit.Plug
      import Conduit.Message
    end
  end
end
