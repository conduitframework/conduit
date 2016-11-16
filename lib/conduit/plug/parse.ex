defmodule Conduit.Plug.Parse do
  use Conduit.Plug.Builder

  @default_content_type "application/json"
  def call(message, opts) do
    content_type =
      Keyword.get(opts, :content_type)
      || get_in(message, [:meta, :content_type])
      || @default_content_type

    Conduit.ContentType.parse(message, content_type, opts)
  end
end
