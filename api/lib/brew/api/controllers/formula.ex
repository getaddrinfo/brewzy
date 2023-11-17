defmodule Brew.Api.Controllers.Formula do
  use Plug.Router
  import Brew.Api.Common.Response, only: [write_error: 4]

  plug :match
  plug :dispatch

  get "/:formula_name" do
    %Plug.Conn{params: %{"formula_name" => _}} = conn

    conn
    |> write_error(404, "Unknown Formula", :unknown_formula)
  end
end
