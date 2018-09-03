defmodule Conduit.Plug.CreatedBy do
  use Conduit.Plug.Builder

  @moduledoc """
  Assigns name of app to created_by of the message.

  ## Examples

      plug Conduit.Plug.CreatedBy, app: "myapp"

      iex> message = Conduit.Plug.CreatedBy.run(%Conduit.Message{}, app: "myapp")
      iex> message.created_by
      "myapp"

  """

  def init(opts) do
    _ = Keyword.fetch!(opts, :app)

    opts
  end

  @doc """
  Assigns created_by.
  """
  def call(message, next, opts) do
    created_by =
      opts
      |> Keyword.get(:app)
      |> to_string

    message
    |> put_created_by(created_by)
    |> next.()
  end
end
