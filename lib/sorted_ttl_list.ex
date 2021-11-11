defmodule SortedTtlList do
  @moduledoc """
  Generate a sorted lists with a ttl for every element in the list.
  """
  use GenServer

  @typedoc """
  The tablename
  """
  @type table :: String.t()
  @typedoc """
  The element key
  """
  @type key :: String.t()
  @typedoc """
  The score to do the sorting
  """
  @type score :: Integer.t()
  @typedoc """
  The time to live used by the `.push/5` method.
  """
  @type ttl :: Integer.t()
  @typedoc """
  The response element will not show the ttl. It will transform it to a timestamp until it is alive.
  """
  @type expire :: Integer.t()
  @typedoc """
  Any aditional data to store with this key
  """
  @type data :: any

  @typedoc """
  A response element
  """
  @type element :: {key, score, expire, data}

  require Logger

  @doc """
  Push a element to the list

  ## Parameters

  * `table` (Binary|Atom) The table name. _Make sure to start the table before_
  * `key` (Binary) The key used to save this element
  * `score` (Integer) The score to sort the list.
  * `ttl` (Integer) The time to live in seconds for this key
  * `data` (Map) *optional* Additional data that belongs to this key

  ## Examples
  	iex>{:ok, tid} = SortedTtlList.start_link( "test_table" )
  	...>{ "mykey", 23, _expire_ts, %{ some: "additional", data2: "save" } } = SortedTtlList.push( tid, "mykey", 23, 3600, %{ some: "additional", data2: "save" } )
  	...>SortedTtlList.size( tid )
  	1
  """
  @spec push(table, key, score, ttl, data) :: :ok
  def push(table, key, score, ttl, data \\ nil) do
    GenServer.call(table |> tbl, {:push, {key, score, ttl, data}})
  end

  @doc """
  get a single key

  ## Parameters

  * `table` (Binary|Atom) The table name.
  * `key` (Binary) The key to get

  ## Examples
  	iex>{:ok, _tid} = SortedTtlList.start_link( "test_table" )
  	...>{ "mykey", 23, _expire_ts, %{ some: "additional", data2: "save" } } = SortedTtlList.push( "test_table", "mykey", 23, 3600, %{ some: "additional", data2: "save" } )
  	...>{ "mykey", 23, _expire_timestamp, %{ some: "additional", data2: "save" } } = SortedTtlList.get( "test_table", "mykey" )
  	...>SortedTtlList.size( "test_table" )
  	1

  	iex>{:ok, _tid} = SortedTtlList.start_link( "test_table" )
  	...>{ "mykey", 23, _expire_ts, %{ some: "additional", data2: "save" } } = SortedTtlList.push( "test_table", "mykey", 23, 2, %{ some: "additional", data2: "save" } )
  	...>{ "mykey", 23, _expire_timestamp, %{ some: "additional", data2: "save" } } = SortedTtlList.get( "test_table", "mykey" )
  	...>:timer.sleep( 2000 )
  	...>nil = SortedTtlList.get( "test_table", "mykey" )
  	...>SortedTtlList.size( "test_table" )
  	0
  """
  @spec get(table, key) :: element | nil
  def get(table, key) do
    GenServer.call(table |> tbl, {:get, key})
  end

  @doc """
  delete a key from the list

  ## Parameters

  * `table` (Binary|Atom) The table name.
  * `key` (Binary) The key used to save this element

  ## Examples
  	iex>{:ok, _tid} = SortedTtlList.start_link( "test_table" )
  	...>{ "mykey", 23, _expire_ts, %{ some: "additional", data2: "save" } } = SortedTtlList.push( "test_table", "mykey", 23, 3600, %{ some: "additional", data2: "save" } )
  	...>:ok = SortedTtlList.delete( "test_table", "mykey" )
  	...>SortedTtlList.size( "test_table" )
  	0
  """
  @spec delete(table, key) :: :ok
  def delete(table, key) do
    GenServer.cast(table |> tbl, {:delete, key})
  end

  @doc """
  list the element in the table sorted by score

  ## Parameters

  * `table` (Binary|Atom) The table to list the elements.
  * `reverse` (Boolean) Sort in reverse order vom high to low.

  ## Examples
  	iex>{:ok, tid} = SortedTtlList.start_link( "test_table" )
  	...>{ "mykeyA", 23, _expire_ts, nil } = SortedTtlList.push( tid, "mykeyA", 23, 3600, nil )
  	...>{ "mykeyB", 13, _expire_ts, nil } = SortedTtlList.push( tid, "mykeyB", 13, 3600, nil )
  	...>[ { "mykeyB", 13, _tsA, nil }, { "mykeyA", 23, _tsB, nil } ] = SortedTtlList.list( tid )
  	...>SortedTtlList.size( tid )
  	2

  	iex>{:ok, tid} = SortedTtlList.start_link( 1337 )
  	...>{ "mykeyA", 23, _expire_ts, nil }= SortedTtlList.push( tid, "mykeyA", 23, 3600, nil )
  	...>{ "mykeyB", 13, _expire_ts, nil }= SortedTtlList.push( tid, "mykeyB", 13, 3600, nil )
  	...>[ { "mykeyA", 23, _tsB, nil }, { "mykeyB", 13, _tsA, nil } ] = SortedTtlList.list( tid, true )
  	...>SortedTtlList.size( tid )
  	2
  """
  @spec list(table, Boolean.t()) :: [element]
  def list(table, reverse \\ false) do
    GenServer.call(table |> tbl, {:list, reverse})
  end

  @doc """
  Get the size of the table

  ## Parameters

  * `table` (Binary|Atom) The table to list the elements.

  ## Examples
  	iex>{:ok, tid} = SortedTtlList.start_link( "test_table" )
  	...>0 = SortedTtlList.size( tid )
  	...>{ "mykey", 23, _expire_ts, nil } = SortedTtlList.push( tid, "mykey", 23, 3600, nil )
  	...>SortedTtlList.size( tid )
  	1
  """
  @spec size(table) :: Integer.t()
  def size(table) do
    GenServer.call(table |> tbl, :size)
  end

  @doc """
  Flush the content of a table

  ## Parameters

  * `table` (Binary|Atom) The table to list the elements.

  ## Examples
  	iex>{:ok, tid} = SortedTtlList.start_link( "test_table" )
  	...>0 = SortedTtlList.size( tid )
  	...>{ "mykey", 23, _expire_ts, nil } = SortedTtlList.push( tid, "mykey", 23, 3600, nil )
  	...>1 = SortedTtlList.size( tid )
  	...>SortedTtlList.flush( tid )
  	...>SortedTtlList.size( tid )
  	0
  """
  @spec flush(table) :: Integer.t()
  def flush(table) do
    GenServer.cast(table |> tbl, :flush)
  end

  @doc """
  Backup the table to dets

  ## Parameters

  * `table` (Binary|Atom) The table to list the elements.

  ## Examples
  	iex>{:ok, tid} = SortedTtlList.start_link( "test_table_backup", true )
  	...>SortedTtlList.push( tid, "mykey", 23, 3600, nil )
  	...>SortedTtlList.backup( tid )
  	:ok
  """
  @spec backup(table) :: Integer.t()
  def backup(table) do
    GenServer.cast(table |> tbl, :backup)
  end

  @doc """
  Check if a table exists

  ## Parameters

  * `table` (Binary|Atom) The table to check.

  ## Examples
  	iex>{:ok, _tid} = SortedTtlList.start_link( "hello" )
  	...>SortedTtlList.exists( "hello" )
  	true

  	iex>SortedTtlList.exists( "nobody_here" )
  	false
  """
  @spec exists(table) :: Boolean.t()
  def exists(table) do
    tname = table |> tbl

    if Process.whereis(tname) != nil do
      GenServer.call(tname, :exists)
    else
      false
    end
  end

  # GENSERVER API
  @doc """
  Start a table

  ## Parameters

  * `tablename` (Binary|Atom) The table to create.
  * `persist` (Boolean, default: `true`) Persist this table on start/exits from/to the disk.

  ## Examples
  	iex>{isok, _pid } = SortedTtlList.start_link( "hello" )
  	...>isok
  	:ok

  	iex>{isok, _pid } = SortedTtlList.start_link( "helloPersist", true )
  	...>isok
  	:ok
  """
  @spec start_link(String.t(), boolean) :: {:ok, {pid, boolean}}
  def start_link(tablename, persist \\ false) do
    table = tablename |> tbl
    GenServer.start_link(__MODULE__, [table, persist], name: table)
  end

  def init([table, persist]) do
    Logger.debug("startet list expire with tablename: #{table}")
    # start receiving messages

    tid = :ets.new(table, [:set, :named_table, :public])

    if persist do
      Process.flag(:trap_exit, true)
      restore(tid)
    end

    {:ok, [tid, persist]}
  end

  def terminate(reason, [tid, persist]) do
    Logger.debug("terminate(#{reason}) - #{tid}")

    if persist do
      case backup(tid) do
        :ok ->
          Logger.debug("backup done - #{tid}")
          reason

        _ ->
          Logger.warn("backup error")
          reason
      end
    else
      reason
    end
  end

  def handle_call({:push, {key, score, ttl, data}}, _from, [tid, _persist] = state) do
    exp = now() + ttl
    saved = {key, score, exp, data}
    :ets.insert(tid, saved)
    Logger.debug("added key \"#{key}\" to table '#{tid}'")
    {:reply, saved, state}
  end

  # @lint { Credo.Check.Refactor.PipeChainStart, false }
  def handle_call({:list, reverse}, _from, [tid, _persist] = state) do
    date = now()

    {found, expired} =
      :ets.tab2list(tid)
      |> Enum.reduce({[], []}, fn {key, score, ttl, data}, {fnd, exp} ->
        if check_el(ttl, date) do
          {[{key, score, ttl, data} | fnd], exp}
        else
          {fnd, [{key, score, ttl, data} | exp]}
        end
      end)

    # delete the expired keys
    expired |> delete_key(tid)

    list =
      found
      |> Enum.sort(&sort_list(&1, &2, reverse))
      |> Enum.to_list()

    {:reply, list, state}
  end

  def handle_call({:get, key}, _from, [tid, _persist] = state) do
    case get_key(key, tid) do
      {key, _score, ttl, _data} = el ->
        if check_el(ttl) do
          {:reply, el, state}
        else
          # delete an expired key
          key |> delete_key(tid)
          {:reply, nil, state}
        end

      nil ->
        {:reply, nil, state}
    end
  end

  def handle_call(:size, _from, [tid, _persist] = state) do
    {:reply, :ets.info(tid, :size), state}
  end

  def handle_call(:exists, _from, [tid, _persist] = state) do
    if :ets.info(tid) != :undefined do
      {:reply, true, state}
    else
      {:reply, false, state}
    end
  end

  defp get_key(key, tid) do
    case :ets.lookup(tid, key) do
      [{key, score, ttl, data}] ->
        {key, score, ttl, data}

      [] ->
        nil
    end
  end

  def handle_cast({:delete, key}, [tid, _persist] = state) do
    delete_key(key, tid)
    Logger.debug("deleted key \"#{key}\" from table '#{tid}'")
    {:noreply, state}
  end

  def handle_cast(:flush, [tid, _persist] = state) do
    :ets.delete_all_objects(tid)
    Logger.info("flushed table '#{tid}'")
    {:noreply, state}
  end

  def handle_cast(:backup, [tid, persist] = state) do
    if persist do
      case get_dets(tid) do
        {:ok, dtid} ->
          :ets.to_dets(tid, dtid)
          size = :dets.info(dtid, :size)
          :dets.close(dtid)
          Logger.debug("persist #{size} elements of '#{tid}' to disk")
          {:noreply, state}

        {:error, err} ->
          Logger.warn("could not backup data: #{inspect(err)}")
          {:noreply, state}

        unkown ->
          Logger.error("unkown dets response: #{inspect(unkown)}")
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  # ####################
  # PRIVATE FUNCTIONS
  # ####################

  defp get_dets(tid) do
    file =
      "#{get_conf(:folder, "", :string)}sorted_ttl_list_#{tid}.dets"
      |> String.downcase()
      |> String.to_charlist()

    :dets.open_file("pers_#{__MODULE__}_#{tid}",
      type: :set,
      file: file,
      auto_save: :infinity
    )
  end

  defp restore(tid) do
    case get_dets(tid) do
      {:ok, dtid} ->
        :ets.from_dets(tid, dtid)
        size = :ets.info(tid, :size)
        :dets.close(dtid)
        Logger.info("started '#{tid}' with restore of #{size} elements")

      {:error, err} ->
        Logger.warn("could not restore data: #{inspect(err)}")

      unkown ->
        Logger.error("unkown dets response: #{inspect(unkown)}")
    end
  end

  defp delete_key(nil, _tid), do: :ok
  defp delete_key([], _tid), do: :ok
  defp delete_key({key, _, _, _}, tid), do: delete_key(key, tid)

  defp delete_key(keys, tid) when is_list(keys) do
    keys |> Enum.each(&delete_key(&1, tid))
  end

  defp delete_key(key, tid) when is_binary(key) do
    :ets.delete(tid, key)
  end

  defp sort_list({key_a, score_a, _, _}, {key_b, score_b, _, _}, reverse) do
    cond do
      score_a == score_b && key_a < key_b ->
        sort_dir(true, reverse)

      score_a == score_b && key_a > key_b ->
        sort_dir(false, reverse)

      score_a < score_b ->
        sort_dir(true, reverse)

      score_a > score_b ->
        sort_dir(false, reverse)

      true ->
        sort_dir(false, reverse)
    end
  end

  defp sort_dir(dir, false), do: dir
  defp sort_dir(true, true), do: false
  defp sort_dir(false, true), do: true

  defp check_el(ttl), do: check_el(ttl, now())

  defp check_el(ttl, date) do
    if date < ttl do
      true
    else
      false
    end
  end

  defp tbl(table) when is_binary(table), do: String.to_atom(table)
  defp tbl(table) when is_integer(table), do: String.to_atom("#{table}")
  defp tbl(table) when is_atom(table), do: table
  defp tbl(table) when is_pid(table), do: table

  defp now, do: ts(DateTime.utc_now())
  defp ts(date), do: date |> DateTime.to_unix(:second)

  defp get_conf({module, key}) do
    get_conf({module, key, nil, :string})
  end

  defp get_conf({module, key, default}) do
    get_conf({module, key, default, :string})
  end

  defp get_conf({module, key, default, type}) do
    cval = process_conf_env(Application.get_env(module, key, default))

    case {type, cval} do
      {_undefined, nil} ->
        nil

      {:string, val} when is_number(val) ->
        Integer.to_string(val)

      {:string, val} when is_binary(val) ->
        val

      {:number, val} when is_binary(val) ->
        String.to_integer(val)

      {:number, val} when is_number(val) ->
        val

      {_undefined, val} ->
        val
    end
  end

  defp get_conf(key) when is_atom(key) do
    get_conf({:sorted_ttl_list, key, nil, :string})
  end

  defp get_conf(key, default) do
    case default do
      default when is_number(default) ->
        get_conf({:sorted_ttl_list, key, default, :number})

      default when is_binary(default) ->
        get_conf({:sorted_ttl_list, key, default, :string})
    end
  end

  defp get_conf(key, default, type) do
    get_conf({:sorted_ttl_list, key, default, type})
  end

  defp process_conf_env({:system, envvar, default}) do
    sysvar = System.get_env(envvar)

    if sysvar == nil do
      default
    else
      sysvar
    end
  end

  defp process_conf_env(val) do
    val
  end
end
