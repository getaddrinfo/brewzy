defmodule Brew.Api do
  alias Brew.Api.Common.Error
  use Plug.Router

  import Brew.Api.Common.JSON

  plug Plug.RequestId # useful to register a request id
  plug :match # matches the incoming route
  plug :dispatch # dispatches the request to the fn



  get "/meta" do
    {:ok, next_sync_in_millis} = Brew.Job.Syncer.next_sync_in()
    {:ok, time} = DateTime.now("Etc/UTC")

    at = time
    |> DateTime.add(next_sync_in_millis, :millisecond)
    |> DateTime.to_iso8601()

    conn
    |> send_resp(200, to_json(%{}))
  end

  forward "/formulas", to: Brew.Api.Controllers.Formula
  forward "/casks", to: Brew.Api.Controllers.Cask

  match _ do
    conn
    |> Error.write(404, Error.HTTP.not_found())
  end
end
