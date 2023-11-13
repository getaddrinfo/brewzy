defmodule Brew.Cache.Casks do
  @behaviour Brew.Cache
  use GenServer

  defmodule State do
    defstruct [:table]

    @type t :: %__MODULE__{
      table: :ets.table()
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl true
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  @impl true
  def update(data) do
    GenServer.call(__MODULE__, {:set, data})
  end

  def by_name(name) do
    GenServer.call(__MODULE__, {:lookup_name, name})
  end

  def by_hash(hash) do
    GenServer.call(__MODULE__, {:lookup_hash, hash})
  end

  @spec init(any()) :: {:ok, State.t()}
  @impl true
  def init(_) do
    tab = :ets.new(
      :brew_cache_casks,
      [:ordered_set, :protected]
    )

    {:ok, %State{table: tab}}
  end

  @impl true
  def handle_call({:set, data}, _from, %State{table: table} = state) do
    mapped = Enum.map(data, fn it -> {
      Map.get(it, "name"),
      Map.get(it, "hash"),
      it
    } end)

    :ets.insert(table, mapped)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_table_reference, _from, %State{table: table} = state) do
    {:reply, {:ok, table}, state}
  end

  @impl true
  def handle_call({:lookup_name, name}, _from, %State{table: table} = state) do
    # do something to lookup in ets

    res = case :ets.lookup(table, name) do
      [{^name, hash, data}] ->
        data = data
        |> Map.put("hash", hash)
        |> Map.put("name", name)

        {:ok, data}
      [] -> {:error, :miss}
    end

    {:reply, res, state}
  end


  @impl true
  def handle_call(:clear, _from, %State{table: table} = state) do
    :ets.delete_all_objects(table)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:lookup_hash, hash}, _from, %State{table: table} = state) do
    res = case :ets.match_object(table, {:"$0", hash, :"$2"}) do
      [{^hash, name, data}] ->
        data = data
        |> Map.put("hash", hash)
        |> Map.put("name", name)

        {:ok, data}
      [] -> {:error, :miss}
    end

    {:reply, res, state}
  end
end
