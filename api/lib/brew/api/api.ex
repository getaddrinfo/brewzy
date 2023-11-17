defmodule Brew.Api do
  use Plug.Router
  import Brew.Api.Common.Response, only: [write_error: 4]

  plug Plug.RequestId # useful to register a request id
  plug :match # matches the incoming route
  plug :dispatch # dispatches the request to the fn

  forward "/meta", to: Brew.Api.Controllers.Meta
  forward "/formulas", to: Brew.Api.Controllers.Formula
  forward "/casks", to: Brew.Api.Controllers.Cask

  match _ do
    conn
    |> write_error(404, "Not Found", :not_found)
  end
end
