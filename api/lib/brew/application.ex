defmodule Brew.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Brew.Api, port: 8080},

      # caches (ets)
      {Brew.Cache.Formulae, name: Brew.Cache.Formulae},
      {Brew.Cache.Casks, name: Brew.Cache.Casks},
      # Starts a worker by calling: Brew.Worker.start_link(arg)
      # {Brew.Worker, arg}
    ] ++ jobs()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Brew.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def jobs do
    is_enabled = fn job -> job.is_enabled? end
    to_child_spec = fn job -> {job, name: job} end

    [
      Brew.Job.Git,
      Brew.Job.Syncer
    ]
    |> Enum.filter(is_enabled)
    |> Enum.map(to_child_spec)
  end
end
