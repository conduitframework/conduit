defmodule Conduit.ContentType do
  @callback format(Conduit.Message.t, Keyword.t) :: Conduit.Message.t
  @callback parse(Conduit.Message.t, Keyword.t) :: Conduit.Message.t

  @default_content_types [{"application/json", Conduit.ContentType.JSON}]

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.ContentType
      import Conduit.Message
    end
  end

  def format(message, type, opts) do
    content_type(type).format(message, opts)
  end

  def parse(message, type, opts) do
    content_type(type).parse(message, opts)
  end

  for {type, content_type} <- Application.get_env(:conduit, Conduit.ContentType, []) ++ @default_content_types do
    quote do
      def content_type(unquote(type)), do: unquote(content_type)
    end
  end

  def content_type(content_type) do
    raise "No encoder found for #{content_type}"
  end
end
