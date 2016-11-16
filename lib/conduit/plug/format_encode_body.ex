defmodule Conduit.Plug.FormatEncodeBody do
  use Conduit.Plug.Builder

  def call(message, opts) do
    Conduit.Format.encode(message, opts)
  end
end
