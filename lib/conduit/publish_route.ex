defmodule Conduit.PublishRoute do
  @moduledoc """
  Configuration for a publish route
  """

  @type name :: atom
  @type pipelines :: [atom]
  @type opts :: Keyword.t() | (() -> Keyword.t())
  @type t :: %__MODULE__{
          name: atom,
          opts: Keyword.t(),
          pipelines: [atom]
        }

  defstruct name: nil, opts: [], pipelines: []

  @doc """
  Creates a new PublishRoute struct

  ## Examples

      iex> Conduit.PublishRoute.new(:user_created, [:out_tracking, :error_handling], to: "my_app.created.user")
      %Conduit.PublishRoute{
        name: :user_created,
        pipelines: [:out_tracking, :error_handling],
        opts: [to: "my_app.created.user"]}
      iex> Conduit.PublishRoute.new(:dynamic, [:out_tracking], fn -> [to: "my_app.dynamic.queue"] end)
      %Conduit.PublishRoute{
        name: :dynamic,
        pipelines: [:out_tracking],
        opts: [to: "my_app.dynamic.queue"]}
  """
  @spec new(name, pipelines, opts) :: t()
  def new(name, pipelines \\ [], opts \\ [])
  def new(name, pipelines, opts) when is_function(opts), do: new(name, pipelines, opts.())

  def new(name, pipelines, opts) when is_atom(name) and is_list(pipelines) and is_list(opts) do
    %__MODULE__{
      name: name,
      pipelines: pipelines,
      opts: opts
    }
  end
end
