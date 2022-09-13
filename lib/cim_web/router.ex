defmodule CimWeb.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias CimWeb.StoreController

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart],
    pass: ["*/*"]
  )

  plug(:match)
  plug(:dispatch)

  put "/:database/:key" do
    StoreController.put(conn)
  end

  delete "/:database" do
    StoreController.delete_database(conn)
  end

  delete "/:database/:key" do
    StoreController.delete_key(conn)
  end

  get "/:database/:key" do
    StoreController.get(conn)
  end

  post "/:database" do
    StoreController.post(conn)
  end

  match _ do
    send_resp(conn, 400, "")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, _context) do
    conn
    |> put_resp_header("content-type", "text/plain")
    |> send_resp(500, "Internal Server Error")
  end
end
