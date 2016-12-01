defmodule SortedTtlList do
	@moduledoc """
	Generate a sorted lists with a ttl for every element in the list.
	"""
	use GenServer
	
	@typedoc """
	The tablename
	"""
	@type table :: String.t
	@typedoc """
	The element key
	"""
	@type key :: String.t
	@typedoc """
	The score to do the sorting
	"""
	@type score :: Integer.t
	@typedoc """
	The time to live used by the `.push/5` method.
	"""
	@type ttl :: Integer.t
	@typedoc """
	The response element will not show the ttl. It will transform it to a timestamp until it is alive.
	"""
	@type expire :: Integer.t
	@typedoc """
	Any aditional data to store with this key
	"""
	@type data :: any
	
	@typedoc """
	A response element
	"""
	@type element :: { key, score, expire, data }
	
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
		...>:ok = SortedTtlList.push( tid, "mykey", 23, 3600, %{ some: "additional", data2: "save" } )
		...>SortedTtlList.size( tid )
		1
	"""
	@spec push( table, key, score, ttl, data ) :: :ok
	def push( table, key, score, ttl, data \\ nil ) do
		GenServer.cast( table |> tbl, { :push, { key, score, ttl, data } } )
	end
	
	
	@doc """
	get a single key

	## Parameters

	* `table` (Binary|Atom) The table name.
	* `key` (Binary) The key to get

	## Examples
		iex>{:ok, _tid} = SortedTtlList.start_link( "test_table" )
		...>:ok = SortedTtlList.push( "test_table", "mykey", 23, 3600, %{ some: "additional", data2: "save" } )
		...>{ "mykey", 23, _expire_timestamp, %{ some: "additional", data2: "save" } } = SortedTtlList.get( "test_table", "mykey" )
		...>SortedTtlList.size( "test_table" )
		1
		
		iex>{:ok, _tid} = SortedTtlList.start_link( "test_table" )
		...>:ok = SortedTtlList.push( "test_table", "mykey", 23, 2, %{ some: "additional", data2: "save" } )
		...>{ "mykey", 23, _expire_timestamp, %{ some: "additional", data2: "save" } } = SortedTtlList.get( "test_table", "mykey" )
		...>:timer.sleep( 2000 )
		...>nil = SortedTtlList.get( "test_table", "mykey" )
		...>SortedTtlList.size( "test_table" )
		0
	"""
	@spec get( table, key ) :: element | nil
	def get( table, key ) do
		GenServer.call( table |> tbl , { :get, key } ) 
	end
	
	@doc """
	delete a key from the list

	## Parameters

	* `table` (Binary|Atom) The table name.
	* `key` (Binary) The key used to save this element

	## Examples
		iex>{:ok, _tid} = SortedTtlList.start_link( "test_table" )
		...>:ok = SortedTtlList.push( "test_table", "mykey", 23, 3600, %{ some: "additional", data2: "save" } )
		...>:ok = SortedTtlList.delete( "test_table", "mykey" )
		...>SortedTtlList.size( "test_table" )
		0
	"""
	@spec delete( table, key ) :: :ok
	def delete( table, key ) do
		GenServer.cast( table |> tbl, { :delete, key } )
	end
	
	@doc """
	list the element in the table sorted by score

	## Parameters

	* `table` (Binary|Atom) The table to list the elements.
	* `reverse` (Boolean) Sort in reverse order vom high to low.

	## Examples
		iex>{:ok, tid} = SortedTtlList.start_link( "test_table" )
		...>:ok = SortedTtlList.push( tid, "mykeyA", 23, 3600, nil )
		...>:ok = SortedTtlList.push( tid, "mykeyB", 13, 3600, nil )
		...>[ { "mykeyB", 13, _tsA, nil }, { "mykeyA", 23, _tsB, nil } ] = SortedTtlList.list( tid )
		...>SortedTtlList.size( tid )
		2
		
		iex>{:ok, tid} = SortedTtlList.start_link( "test_table" )
		...>:ok = SortedTtlList.push( tid, "mykeyA", 23, 3600, nil )
		...>:ok = SortedTtlList.push( tid, "mykeyB", 13, 3600, nil )
		...>[ { "mykeyA", 23, _tsB, nil }, { "mykeyB", 13, _tsA, nil } ] = SortedTtlList.list( tid, true )
		...>SortedTtlList.size( tid )
		2
	"""
	@spec list( table ) :: [ element ]
	def list( table, reverse \\ false ) do
		GenServer.call( table |> tbl , { :list, reverse } ) 
	end
	
	@doc """
	Get the size of the table

	## Parameters

	* `table` (Binary|Atom) The table to list the elements.

	## Examples
		iex>{:ok, tid} = SortedTtlList.start_link( "test_table" )
		...>0 = SortedTtlList.size( tid )
		...>:ok = SortedTtlList.push( tid, "mykey", 23, 3600, nil )
		...>SortedTtlList.size( tid )
		1
	"""
	@spec size( table ) :: Integer.t
	def size( table ) do
		GenServer.call( table |> tbl , :size )
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
	@spec exists( table ) :: Boolean.t
	def exists( table ) do
		tname = table |> tbl 
		if Process.whereis( tname ) != nil do
			GenServer.call( tname , :exists )
		else
			false
		end
	end
	
	# GENSERVER API
	@spec start_link( table ) :: { :ok, pid }
	def start_link( tablename ) do
		table = tablename |> tbl
		GenServer.start_link( __MODULE__, [ table ] , name: table )
	end
	
	def init( [ table ] ) do
		Logger.debug "startet list expire with tablename: #{table}"
		
		# start receiving messages
		tid = :ets.new( table, [ :set, :named_table, :public ] )
		
		{ :ok, tid }
	end	
	
	def handle_cast( { :push, { key, score, ttl, data } }, tid ) do
		
		exp = now( ) + ttl
		
		:ets.insert( tid, { key, score, exp, data } )
		Logger.debug "added key \"#{key}\" to table '#{tid}'"
		{ :noreply, tid }
	end
	
	def handle_cast( { :delete, key }, tid ) do
		delete_key( key, tid )
		Logger.debug "deleted key \"#{key}\" from table '#{tid}'"
		{ :noreply, tid }
	end
	
	
	@lint { Credo.Check.Refactor.PipeChainStart, false }
	def handle_call( { :list, reverse }, _from, tid ) do
		IO.inspect "list dir: #{reverse}"
		date = now( )
		{ found, expired } = :ets.tab2list( tid )
			|> Enum.reduce( { [ ], [ ] }, fn ( { key, score, ttl, data }, { fnd, exp } ) ->
					if check_el( ttl, date ) do
						{ [ { key, score, ttl, data } | fnd ], exp }
					else
						{ fnd, [ { key, score, ttl, data } | exp ] }
					end
				end )
		
		# delete the expired keys
		expired |> delete_key( tid )
		
		list = found
			|> Enum.sort( &( sort_list( &1, &2, reverse ) ) )
			|> Enum.to_list
		
		{ :reply, list, tid }
	end
	
	def handle_call( { :get, key }, _from, tid ) do
		case get_key( key, tid ) do
			{ key, _score, ttl, _data } = el ->
				if check_el( ttl ) do
					{ :reply, el, tid }
				else
					# delete an expired key
					key |> delete_key( tid )
					{ :reply, nil, tid }
				end
			nil ->
				{ :reply, nil, tid }
		end
	end
	
	def handle_call( :size, _from, tid ) do
		{ :reply, :ets.info( tid, :size ), tid }
	end
	
	def handle_call( :exists, _from, tid ) do
		if :ets.info( tid ) != :undefined do
			{ :reply, true, tid }
		else
			{ :reply, false, tid }
		end
	end
	
	defp get_key( key, tid ) do
		case :ets.lookup( tid, key ) do
			[ { key, score, ttl, data } ] ->
				{ key, score, ttl, data }
			[ ] ->
				nil
		end
	end
	
	
	defp delete_key( nil, _tid ), do: :ok
	defp delete_key( [ ], _tid ), do: :ok
	defp delete_key( { key, _, _, _ }, tid ), do: delete_key( key, tid  )
	defp delete_key( keys, tid ) when is_list( keys ) do
		keys |>	Enum.each( &( delete_key( &1, tid ) ) )
	end
	defp delete_key( key, tid ) when is_binary( key ) do
		:ets.delete( tid, key )
	end
	
	defp sort_list( { key_a, score_a, _, _ }, { key_b, score_b, _, _ }, reverse ) do
		cond do
			score_a == score_b && key_a < key_b ->
				sort_dir( true, reverse )
			score_a == score_b && key_a > key_b ->
				sort_dir( false, reverse )
			score_a < score_b ->
				sort_dir( true, reverse )
			score_a > score_b ->
				sort_dir( false, reverse )
			true ->
				sort_dir( false, reverse )
		end
	end
	
	defp sort_dir( dir, false ), do: dir
	defp sort_dir( true, true ), do: false
	defp sort_dir( false, true ), do: true
	
	defp check_el( ttl ), do: check_el( ttl, now( ) )
	defp check_el( ttl, date ) do
		if date < ttl do
			true
		else
			false
		end
	end
	
	defp tbl( table ) when is_binary( table ), do: String.to_atom( table )
	defp tbl( table ) when is_integer( table ), do: String.to_atom( "#{table}" )
	defp tbl( table ) when is_atom( table ), do: table
	defp tbl( table ) when is_pid( table ), do: table
	
	defp now, do: ts( DateTime.utc_now( ) )
	defp ts( date ), do: date |> DateTime.to_unix( :seconds )
end
