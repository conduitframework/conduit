defmodule Conduit.Plug.FormatDecodeBody do
  use Conduit.Plug.Builder

  def call(message, opts) do
    Conduit.Format.decode(message, opts)
  end
end
