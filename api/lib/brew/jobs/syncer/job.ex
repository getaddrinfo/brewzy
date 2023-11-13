defmodule Brew.Job.Syncer do
  alias Brew.Job.Syncer.API
  use GenServer
  use Brew.Job, every: 60 * 1000 * 15

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def next_sync_in() do
    GenServer.call(__MODULE__, :next_sync_in)
  end

  @impl true
  def setup(_) do
    {:ok, nil}
  end

  @impl true
  def handle_call(:next_sync_in, _from, state) do
    {:reply, time_until_next_execution(), state}
  end

  # job implementation
  @impl true
  def perform do
    Task.start(&run_formulae/0)
    Task.start(&run_casks/0)
  end


  defp run_formulae do
    formulae = get_formulae()
    :ok = Brew.Cache.Formulae.update(formulae)
    Logger.debug("updated formulae")
  end

  defp run_casks do
    casks = get_casks()
    :ok = Brew.Cache.Casks.update(casks)
    Logger.debug("updated casks")
  end

  defp get_casks() do
    Logger.debug("fetching casks")
    {:ok, casks} = API.casks()
    Logger.debug("fetched casks")


    casks.body
  end

  defp get_formulae() do
    Logger.debug("fetching formulae")
    {:ok, response} = API.formulae()
    Logger.debug("fetched formulae")

    response.body
  end
end
