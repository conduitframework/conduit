defmodule Conduit.Pipeline do
  @moduledoc """
  Configuration for a pipeline.
  """

  @type name :: atom
  @type plugs :: [Conduit.Plug.t()]
  @type t :: %__MODULE__{
          name: name,
          plugs: plugs
        }

  defstruct name: nil, plugs: []

  @doc """
  Creates a new pipeline struct

  ## Examples

      iex> Conduit.Pipeline.new(:in_tracking, [{:put_message_id, 1}])
      %Conduit.Pipeline{name: :in_tracking, plugs: [{:put_message_id, 1}]}
  """
  @spec new(name, plugs) :: t()
  def new(name, plugs) do
    %__MODULE__{name: name, plugs: plugs}
  end
end
