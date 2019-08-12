defmodule Conduit.PublishRoute do
  @moduledoc """
  Configuration for a publish route
  """

  @type name :: atom
  @type pipelines :: [atom]
  @type config :: Keyword.t()
  @type opts :: Keyword.t() | (() -> Keyword.t()) | (config -> Keyword.t())
  @type t :: %__MODULE__{
          name: atom,
          opts: Keyword.t(),
          pipelines: [atom]
        }

  defstruct name: nil, opts: [], pipelines: []

  @doc """
  Creates a new PublishRoute struct

  ## Examples

      iex> Conduit.PublishRoute.new(
      iex>   :user_created,
      iex>   [:out_tracking, :error_handling],
      iex>   [to: "my_app.created.user"],
      iex>   [])
      %Conduit.PublishRoute{
        name: :user_created,
        pipelines: [:out_tracking, :error_handling],
        opts: [to: "my_app.created.user"]}
      iex> Conduit.PublishRoute.new(
      iex>   :dynamic,
      iex>   [:out_tracking],
      iex>   fn -> [to: "my_app.dynamic.queue"] end,
      iex>   [])
      %Conduit.PublishRoute{
        name: :dynamic,
        pipelines: [:out_tracking],
        opts: [to: "my_app.dynamic.queue"]}
      iex> Conduit.PublishRoute.new(
      iex>   :dynamic,
      iex>   [:out_tracking],
      iex>   fn config -> [to: config[:name]] end,
      iex>   [name: "my_app.dynamic.queue"])
      %Conduit.PublishRoute{
        name: :dynamic,
        pipelines: [:out_tracking],
        opts: [to: "my_app.dynamic.queue"]}
  """
  @spec new(name, pipelines, opts, config) :: t()
  def new(name, pipelines, opts, config) when is_function(opts) do
    new(name, pipelines, eval(name, opts, config), config)
  end

  def new(name, pipelines, opts, _config) when is_atom(name) and is_list(pipelines) and is_list(opts) do
    %__MODULE__{
      name: name,
      pipelines: pipelines,
      opts: opts
    }
  end

  defp eval(name, fun, config), do: eval(:erlang.fun_info(fun, :arity), name, fun, config)

  defp eval({:arity, 0}, _name, fun, _config), do: fun.()
  defp eval({:arity, 1}, _name, fun, config), do: fun.(config)

  defp eval({:arity, arity}, name, _fun, _config) do
    raise Conduit.BadArityError,
          "Expected function passed to publish route #{inspect(name)} to have arity 0 or 1, got #{arity}"
  end
end
