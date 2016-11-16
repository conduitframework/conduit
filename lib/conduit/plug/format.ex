defmodule Conduit.Plug.Format do
  use Conduit.Plug.Builder

  @default_content_type "application/json"
  def call(message, opts) do
    content_type =
      Keyword.get(opts, :content_type)
      || get_in(message, [:meta, :content_type])
      || @default_content_type

    Conduit.ContentType.format(message, content_type, opts)
  end
end
