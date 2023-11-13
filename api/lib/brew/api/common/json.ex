defmodule Brew.Api.Common.JSON do
  @pretty Mix.env() != :prod

  import Plug.Conn, only: [put_resp_content_type: 2, send_resp: 3]

  # TODO: handle {:error, reason}
  def to_json(any) do
    {:ok, encoded} = Jason.encode(any, pretty: @pretty)

    encoded
  end

  def write_json(conn, status, data) do
    data = cond do
      not is_bitstring(data) -> to_json(data)
      true -> data
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, data)
  end
end
