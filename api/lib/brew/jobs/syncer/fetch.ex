defmodule Brew.Job.Syncer.API do
  use Tesla

  @base_url "https://formulae.brew.sh/api"

  plug Tesla.Middleware.BaseUrl, @base_url
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

  def urls do
    [
      @base_url <> "/formula.json",
      @base_url <> "/cask.json"
    ]
  end
end
