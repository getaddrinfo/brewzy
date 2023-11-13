defmodule Brew.Api.Common.Error do
  import Plug.Conn

  alias Brew.Api.Common.Error.Repr
  alias Brew.Api.Common.Error.HTTP

  def not_found do
    HTTP.not_found()
    |> Repr.to_json()
  end

  def write(conn, status, error) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{"error" => error}))
    |> halt()
  end
end
