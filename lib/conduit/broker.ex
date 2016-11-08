defmodule Conduit.Broker do
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise "endpoint expects :otp_app to be given"
      use Supervisor
      use Conduit.Broker.DSL, otp_app: @otp_app

      def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(_opts) do
        import Supervisor.Spec

        config = Application.get_env(@otp_app, __MODULE__)
        adapter = Keyword.get(config, :adapter)

        children = [supervisor(adapter, [
          @otp_app,
          setup,
          subscribers
        ])]

        supervise(children, strategy: :one_for_one)
      end
    end
  end
end
