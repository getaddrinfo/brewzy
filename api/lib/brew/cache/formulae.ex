defmodule Brew.Cache.Formulae do
  use GenServer
  alias Brew.Job.Syncer.Data.Formula
  alias Brew.Cache.Formulae.ETS

  @moduledoc """
  Represents a cleaner (and protective) interface for interacting
  with the underlying ETS table
  """

  @should_produce_raw Mix.env() != :prod

  defmodule State do
    defstruct [:table]

    @type t :: %__MODULE__{
      table: :ets.table()
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def update(new) do
    GenServer.call(__MODULE__, {:set, new})
  end

  def get(name) do
    GenServer.call(__MODULE__, {:get_by_name, name})
  end

  def by_name(name) do
    GenServer.call(__MODULE__, {:lookup_name, name})
  end

  def by_hash(hash) do
    GenServer.call(__MODULE__, {:lookup_hash, hash})
  end

  @spec init(any()) :: {:ok, any()}
  @impl true
  def init(_) do
    ETS.create()

    if @should_produce_raw do
      :ets.new(:brew_formulae_raw, [
        :set,
        :named_table,
        :public
      ])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_call({:set, data}, _from, state) do
    if @should_produce_raw do
      :ets.insert(:brew_formulae_raw, data |> Enum.map(
        fn %Formula{name: name} = formula -> {name, formula} end
      ))
    end

    # TODO: this can be more efficient (group all inserts
    # for each table into one big insert statement...)
    # data
    # |> Enum.map(&ETS.into/1)
    # |> Enum.each(
    #   fn insertables -> insertables |> Enum.each(
    #     fn {table, data} -> :ets.insert(table, data) end
    #   ) end
    # )

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_by_name, name}, _from, state) do
    with {:ok, base} <- ets_get(name),
         {:ok, aliases} <- ets_get_bottles(name) do
      {:reply, {:ok, {base, aliases}}, state}
    else
      {:error, :miss} -> {:reply, {:error, :miss}, state}
    end

    {:reply, nil, state}
  end

  defp ets_get(name) do
    case :ets.lookup(:brew_cache_formulae, name) do
      [data] -> {:ok, data}
      [] -> {:error, :get_name_miss}
    end
  end

  defp ets_get_bottles(_name) do
    {:error, :get_bottles_miss}
  end

  def dump do
    if not @should_produce_raw do
      raise "ENV == :prod"
    end

    :ets.tab2list(:brew_formulae_raw)
    |> Enum.map(fn {_, data} -> data end)
  end
end
