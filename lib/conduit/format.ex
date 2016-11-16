defmodule Conduit.Format do
  @callback encode(Conduit.Message.t, Keyword.t) :: Conduit.Message.t
  @callback decode(Conduit.Message.t, Keyword.t) :: Conduit.Message.t

  @default_formats [{"application/json", Conduit.Format.JSON}]

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.Format
      import Conduit.Message
    end
  end

  def encode(message, opts) do
    message
    |> content_type(opts)
    |> format
    |> apply(:encode, [message, opts])
  end

  def decode(message, opts) do
    message
    |> content_type(opts)
    |> format
    |> apply(:decode, [message, opts])
  end

  defp content_type(message, opts) do
    opts[:content_type] || message.meta.content_type
  end

  for {content_type, format} <- Application.get_env(:conduit, Conduit.Format, []) ++ @default_formats do
    quote do
      def format(unquote(content_type)), do: unquote(format)
    end
  end

  def format(content_type) do
    raise "No encoding found for #{content_type}"
  end
end
