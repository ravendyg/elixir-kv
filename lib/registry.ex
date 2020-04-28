defmodule KV.Registry do
  use GenServer

  ## Client API

  @doc"""
  Starts the registry

  `:name` is always required
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
    # GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc"""
  Looks up the bucket pid for `name` stored in `server`

  Returns `{:ok, pid}` if bucket exists; `:error` otherwise
  """
  def lookup(server, name) do
    # GenServer.call(server, {:lookup, name})
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc"""
  Ensures there is a bucket associated with the given `name` in `server`
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
    # GenServer.cast(server, {:create, name})
  end

  ## GS callbacks

  @impl true
  # def init(:ok) do
  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    # names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  # @impl true
  # def handle_call({:lookup, name}, _from, state) do
  #   {names, _} = state
  #   {:reply, Map.fetch(names, name), state}
  # end

  @impl true
  def handle_call({:create, name}, _from, state) do
  # def handle_cast({:create, name}, state) do
    {names, refs} = state

    case lookup(names, name) do
      {:ok, bucket} ->
        {:reply, bucket, state}
      :error ->
        {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(bucket)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, bucket})
        {:reply, bucket, {names, refs}}
    end
    # if Map.has_key?(names, name) do
    #   {:noreply, state}
    # else
    #   {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
    #   ref = Process.monitor(bucket)
    #   refs = Map.put(refs, ref, name)
    #   names = Map.put(names, name, bucket)
    #   {:noreply, {names, refs}}
    # end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    # names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
