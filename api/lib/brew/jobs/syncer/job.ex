defmodule Brew.Job.Syncer do
  alias Brew.Job.Syncer.Data.Formula
  alias Brew.Job.Syncer.API

  use GenServer
  # TODO: maybe add a name into this?
  use Brew.Job, every: 60 * 1000 * 15

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def timings do
    GenServer.call(__MODULE__, :timings)
  end

  @impl true
  def setup(_) do
    {:ok, nil}
  end

  # job implementation
  @impl true
  def perform do
    Task.start(&update_formulae/0)
    Task.start(&update_casks/0)
  end


  defp update_formulae do
    formulae = get_formulae()
    has_non_acceptable = formulae |> Enum.any?(fn data -> not Vex.valid?(data) end)

    # if there are formulae that failed validation,
    # log them and only include formulae that passed
    # validation.
    formulae = if has_non_acceptable do
      non_acceptable = formulae |> Enum.map(
        fn formula -> {formula.name, Vex.errors(formula)} end
      )

      Logger.warning("#{length(non_acceptable)}/#{length(formulae)} formulae failed validation: #{inspect(non_acceptable)}")
      formulae |> Enum.filter(&Vex.valid?/1)
    else
      formulae
    end

    :ok = Brew.Cache.Formulae.update(formulae)
    Logger.debug("updated formulae")
  end

  defp update_casks do
    casks = get_casks()
    :ok = Brew.Cache.Casks.update(casks)
    Logger.debug("updated casks")
  end

  defp get_casks() do
    Logger.debug("fetching casks")
    {time, {:ok, response}} = :timer.tc(&API.casks/0, [], :millisecond)
    Logger.debug("fetched casks (took = #{time}ms)")


    response.body
  end

  defp get_formulae() do
    Logger.debug("fetching formulae")
    {time, {:ok, response}} = :timer.tc(&API.formulae/0, [], :millisecond)
    Logger.debug("fetched formulae (took = #{time}ms)")

    response.body
    |> Enum.map(&Formula.from/1)
  end
end
