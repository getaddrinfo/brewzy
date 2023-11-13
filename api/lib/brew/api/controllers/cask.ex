defmodule Brew.Api.Controllers.Cask do
  import Plug.Conn
  use Plug.Router

  plug :match
  plug :dispatch

  get "/:cask_name" do
    halt(conn)
  end
end
