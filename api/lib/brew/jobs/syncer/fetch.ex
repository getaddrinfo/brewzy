defmodule Brew.Job.Syncer.API do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://formulae.brew.sh/api"
  plug Tesla.Middleware.Headers, [{"user-agent", "downstream-brew-sync"}]
  plug Tesla.Middleware.JSON

  @spec formulae() :: {:error, any()} | {:ok, Tesla.Env.t()}
  def formulae() do
    get("/formula.json")
  end

  @spec casks() :: {:error, any()} | {:ok, Tesla.Env.t()}
  def casks() do
    get("/cask.json")
  end
end
