defmodule Conduit.Message do

  defstruct meta: %{},
            headers: [],
            body: nil,
            status: :ack,
            assigns: %{}

  alias Conduit.Message

  def put_status(message, status) do
    %{message | status: status}
  end

  def get_meta(message, field) do
    message.meta |> Map.get(field)
  end

  def put_meta(%Message{meta: meta} = message, key, value) do
    %{message | meta: Map.put(meta, key, value)}
  end

  def put_header(%Message{headers: headers} = message, key, value) when is_list(value) do
    %{message | headers: [{key, :array, value}]}
  end
  def put_header(%Message{headers: headers} = message, key, value) when is_binary(value) do
    %{message | headers: [{key, :longstr, value}]}
  end
  def put_header(%Message{headers: headers} = message, key, value) when is_boolean(value) do
    %{message | headers: [{key, :bool, value}]}
  end

  def headers(%Message{} = message) do
    message.headers |> Enum.map(fn {key, _type, value} -> {key, value} end)
  end

  def get_header(%Message{headers: headers} = message, key) do
    headers
    |> Enum.find(fn {k, _, _} -> k == key end)
    |> elem(2)
  end

  def assign(%Message{assigns: assigns} = message, key, value) do
    %{message | assigns: Map.put(assigns, key, value)}
  end
end
