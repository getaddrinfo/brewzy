defmodule Brew.Api.Common.Response do
  @pretty Mix.env() != :prod

  import Plug.Conn, only: [put_resp_content_type: 2, send_resp: 3]
  alias Brew.Api.Common.Error


  def to_json(any) do
    Jason.encode!(any, pretty: @pretty)
  end

  @spec write_json(conn :: Plug.Conn.t(), status :: non_neg_integer(), data ::any()) :: any()
  def write_json(conn, status, data) do
    data = cond do
      not is_bitstring(data) -> to_json(data)
      true -> data
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, data)
  end

  @spec write_error(conn :: Plug.Conn.t(), status :: non_neg_integer(), message :: String.t(), code :: atom()) :: any()
  def write_error(conn, status, message, code), do: write_json(
    conn,
    status,
    Error.to_json(%Error{code: code |> Atom.to_string, message: message})
  )
end
