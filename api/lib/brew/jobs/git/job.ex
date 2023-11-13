defmodule Brew.Job.Git do
  alias Brew.Job.Git.Source

  # TODO: add more?
  @sources [
    Source.for("https://github.com/mongodb/homebrew-brew", "mongodb"),
    Source.for("https://github.com/homebrew-ffmpeg/homebrew-ffmpeg", "ffmpeg"),
    Source.for("https://github.com/denji/homebrew-nginx", "nginx"),
    Source.for("https://github.com/InstantClientTap/homebrew-instantclient", "instantclient"),
    Source.for("https://github.com/osx-cross/homebrew-avr", "avr", :main),
    Source.for("https://github.com/petere/homebrew-postgresql", "postgresql"),
    Source.for("https://github.com/davidchall/homebrew-hep", "hep"),
    Source.for("https://github.com/gromgit/homebrew-fuse", "fuse", :main),
    Source.for("https://github.com/cloudflare/homebrew-cloudflare", "cloudflare")
  ]


  @dir Path.join(:code.priv_dir(:brew), "git")

  require Logger
  use GenServer
  use Brew.Job, every: 60 * 5 * 1000 # 5 minutes

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def execute do
    send(__MODULE__, @force)
  end

  @impl true
  def setup(_) do
    prepare()

    {:ok, nil}
  end

  @impl true
  def perform do
    # sync them
    pending = @sources |> Enum.map(&sync/1)
    Task.yield_many(pending, timeout: 5000) # wait for them all to be finished

    Logger.info("successfully synced external repositories...")

    # parse them all
    # {casks, formulae} = Parser.parse(@sources)
    # Brew.Cache.Formulae.update_from_git(formulae)
    # Brew.Cache.Casks.update_from_git(casks)
  end

  def sync(%Source{url: url, name: name, branch: branch}) do
    Task.async(fn ->
      path = Path.join(@dir, name)
      opts = [cd: path, stderr_to_stdout: true]

      if !File.dir?(path) do
        Logger.info("missing repo for #{name}, initialising")

        :ok = File.mkdir(path)

        System.cmd("git", ["init"], opts)
        System.cmd("git", ["remote", "add", "origin", url], opts)

        Logger.info("created repo (name = #{name}, url = #{url})")
      end

      {_, status} = System.cmd("git", ["pull", "origin", Atom.to_string(branch)], opts)

      Logger.info("synced #{name} (exit code = #{status}, url = #{url})")

      :ok
    end)
  end

  def prepare do
    if !File.dir?(@dir) do
      :ok = File.mkdir(@dir)
    end
  end
end
