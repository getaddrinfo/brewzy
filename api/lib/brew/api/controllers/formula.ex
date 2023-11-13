defmodule Brew.Api.Controllers.Formula do
  use Plug.Router
  import Brew.Api.Common.JSON, only: [write_json: 3]
  alias Brew.Api.Models.Formula.Get

  plug :match
  plug :dispatch

  get "/:formula_name" do
    %Plug.Conn{params: %{"formula_name" => name}} = conn

     case Brew.Cache.Formulae.by_name(name) do
      {:ok, data}
        -> conn |> write_json(200, data |> Get.from)

      {:error, :miss}
        -> conn |> write_json(404, %{"test" => true})
    end
  end
end
