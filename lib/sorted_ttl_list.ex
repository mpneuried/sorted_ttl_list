defmodule SortedTtlList do
	@moduledoc """
	
	"""
	use GenServer
	
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
	def delete( table, key ) do
		GenServer.cast( table |> tbl, { :delete, key } )
	end
	
	@doc """
	list the element in the table sorted by score

	## Parameters

	* `table` (Binary|Atom) The table to list the elements.

	## Examples
		iex>{:ok, tid} = SortedTtlList.start_link( "test_table" )
		...>:ok = SortedTtlList.push( tid, "mykeyA", 23, 3600, nil )
		...>:ok = SortedTtlList.push( tid, "mykeyB", 13, 3600, nil )
		...>[ { "mykeyB", 13, _tsA, nil }, { "mykeyA", 23, _tsB, nil } ] = SortedTtlList.list( tid )
		...>SortedTtlList.size( tid )
		2
	"""
	def list( table ) do
		GenServer.call( table |> tbl , :list ) 
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
	def size( table ) do
		GenServer.call( table |> tbl , :size ) 
	end
	
	# GENSERVER API
		
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
	def handle_call( :list, _from, tid ) do
		
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
			|> Enum.sort( &( sort_list( &1, &2 ) ) )
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
	
	defp sort_list( { key_a, score_a, _, _ }, { key_b, score_b, _, _ } ) do
		cond do
			score_a == score_b && key_a < key_b ->
				true
			score_a == score_b && key_a > key_b ->
				false
			score_a < score_b ->
				true
			score_a > score_b ->
				false
			true ->
				false
		end
	end
	
	defp check_el( { _k, _s, ttl, _d } ), do: check_el( ttl, now( ) )
	defp check_el( ttl ), do: check_el( ttl, now( ) )
	defp check_el( { _k, _s, ttl, _d }, date ), do: check_el( ttl, date )
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
