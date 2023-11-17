defmodule Brew.Api.Controllers.Meta do
  use Plug.Router
  import Brew.Api.Common.Response

  alias Brew.Api.Models.Meta

  plug :match
  plug :dispatch

  @sources %{
    "git" => Brew.Job.Git.sources()
    |> Enum.map(&Meta.Source.Git.from/1),
    "core" => Brew.Job.Syncer.API.urls()
  }


  get "" do
    {:ok, {_, core_last_synced_at}} = Brew.Job.Syncer.timings()
    {:ok, {_, git_last_synced_at}} = Brew.Job.Git.timings()

    conn
    |> write_json(200, %Meta{
      schedule: %{
        "git" => %Meta.Schedule{
          last_executed_at: git_last_synced_at,
          period: Brew.Job.Git.every
        },
        "core" => %Meta.Schedule{
          last_executed_at: core_last_synced_at,
          period: Brew.Job.Git.every
        }
      },
      sources: @sources
    })
  end
end
