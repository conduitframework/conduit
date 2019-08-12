defmodule Conduit.Config do
  @moduledoc """
  Manages access to the config for a broker process
  """

  import Kernel, except: [apply: 3]

  @type otp_app :: atom()
  @type override_opts :: Keyword.t()
  @type t :: Keyword.t()

  @doc false
  @spec new(otp_app, Conduit.Broker.t(), override_opts) :: t
  def new(otp_app, broker, override_opts) do
    config = apply(otp_app, broker, override_opts)

    table =
      broker
      |> Conduit.broker_name(config)
      |> :ets.new([:set, :public, :named_table])

    :ets.insert(table, {:config, config})

    config
  end

  @doc false
  @spec apply(otp_app, Conduit.Broker.t(), override_opts) :: t
  def apply(otp_app, broker, override_opts) do
    otp_app
    |> Application.get_env(broker, [])
    |> Keyword.merge(override_opts)
  end

  @doc false
  @spec get(Conduit.Broker.t(), Conduit.postfix()) :: t
  def get(broker, postfix) do
    broker
    |> Conduit.broker_name(postfix)
    |> :ets.lookup(:config)
    |> case do
      [] -> []
      [{:config, config}] -> config
    end
  end
end
