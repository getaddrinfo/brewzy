defmodule Brew.Job do
  @callback perform() :: any()
  @callback setup(init_arg :: term()) ::
    {:ok, any()}
    | {:ok, any(), timeout() | :hibernate | {:continue, continue_arg :: term() } }
    | :ignore
    | {:stop, reason :: any()}


  defmacro __using__(opts) do
    every = Keyword.fetch!(opts, :every)
    enabled = Keyword.get(opts, :enabled, true)

    quote do
      @behaviour Brew.Job
      @timer_key :job_schedule_timer

      @cmd :job_execute
      @force :job_execute_no_reschedule
      @period unquote(every)

      @impl true
      def init(args) do
        trigger()
        setup(args)
      end

      def is_enabled? do
        unquote(enabled)
      end

      @impl true
      def handle_info(@cmd, state) do
        run()

        Process.put(@timer_key, schedule())
        {:noreply, state}
      end

      @impl true
      def handle_info(@force, state) do
        run()
        {:noreply, state}
      end

      @impl true
      def handle_call(:job_force_execution, _from, state) do
        # in a handle_call so `self()` points to the correct process
        send(self(), @force)
      end

      defp run do
        Task.start(&perform/0)
      end

      defp trigger do
        # send the command to run the job to the current process
        # it will be put into mailbox for the process and eventually
        # handled
        send(self(), @cmd)
      end

      @spec schedule() :: reference()
      defp schedule do
        Process.send_after(self(), @cmd, @period)
      end

      @spec time_until_next_execution() :: {:ok, non_neg_integer()} | {:error, :timer_not_scheduled} | {:error, :no_timer}
      defp time_until_next_execution do
        case Process.get(@timer_key, nil) do
          nil -> {:error, :no_timer}
          val -> case Process.read_timer(val) do
            time -> {:ok, time}
            nil -> {:error, :timer_not_scheduled}
          end
        end
      end
    end
  end

  def attach(mod) do
    DynamicSupervisor.start_child(Brew.Job.Supervisor, {mod, name: mod})
  end
end
