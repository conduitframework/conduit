defmodule Conduit.SubscribeRoute do
  @moduledoc """
  Configuration for a subscribe route
  """

  @type name :: atom
  @type subscriber :: module
  @type config :: Keyword.t()
  @type opts :: Keyword.t() | (() -> Keyword.t()) | (config -> Keyword.t())
  @type pipelines :: [atom]
  @type t :: %__MODULE__{
          name: atom,
          subscriber: module,
          opts: Keyword.t(),
          pipelines: [atom]
        }

  defstruct name: nil, subscriber: nil, opts: [], pipelines: []

  @doc """
  Creates a new SubscribeRoute struct

  ## Examples

      iex> Conduit.SubscribeRoute.new(
      iex>   :user_created,
      iex>   MyApp.UserCreatedEmailSubscriber,
      iex>   [:in_tracking, :error_handling],
      iex>   [from: "my_app.created.user"],
      iex>   [])
      %Conduit.SubscribeRoute{
        name: :user_created,
        subscriber: MyApp.UserCreatedEmailSubscriber,
        pipelines: [:in_tracking, :error_handling],
        opts: [from: "my_app.created.user"]}
      iex> Conduit.SubscribeRoute.new(
      iex>   :dynamic,
      iex>   MyApp.DynamicSubscriber,
      iex>   [:in_tracking],
      iex>   fn -> [from: "my_app.dynamic.queue"] end,
      iex>   [])
      %Conduit.SubscribeRoute{
        name: :dynamic,
        subscriber: MyApp.DynamicSubscriber,
        pipelines: [:in_tracking],
        opts: [from: "my_app.dynamic.queue"]}
      iex> Conduit.SubscribeRoute.new(
      iex>   :dynamic,
      iex>   MyApp.DynamicSubscriber,
      iex>   [:in_tracking],
      iex>   fn config -> [from: config[:name]] end,
      iex>   [name: "my_app.dynamic.queue"])
      %Conduit.SubscribeRoute{
        name: :dynamic,
        subscriber: MyApp.DynamicSubscriber,
        pipelines: [:in_tracking],
        opts: [from: "my_app.dynamic.queue"]}
  """
  @spec new(name, subscriber, pipelines, opts, config) :: t()
  def new(name, subscriber, pipelines, opts, config) when is_function(opts) do
    new(name, subscriber, pipelines, eval(name, opts, config), config)
  end

  def new(name, subscriber, pipelines, opts, _config)
      when is_atom(name) and is_atom(subscriber) and is_list(pipelines) and is_list(opts) do
    %__MODULE__{name: name, subscriber: subscriber, pipelines: pipelines, opts: opts}
    |> expand()
  end

  defp expand(%__MODULE__{} = route) do
    %{route | opts: expand_opts(route.opts)}
  end

  defp expand_opts([{:from, fun} | rest]) when is_function(fun) do
    [{:from, fun.()} | expand_opts(rest)]
  end

  defp expand_opts([item | rest]) do
    [item | expand_opts(rest)]
  end

  defp expand_opts([]), do: []

  defp eval(name, fun, config), do: eval(:erlang.fun_info(fun, :arity), name, fun, config)

  defp eval({:arity, 0}, _name, fun, _config), do: fun.()
  defp eval({:arity, 1}, _name, fun, config), do: fun.(config)

  defp eval({:arity, arity}, name, _fun, _config) do
    raise Conduit.BadArityError,
          "Expected function passed to subscribe route #{inspect(name)} to have arity 0 or 1, got #{arity}"
  end
end
