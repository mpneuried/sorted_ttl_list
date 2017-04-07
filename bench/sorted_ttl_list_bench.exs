{ :ok, _tidS } = SortedTtlList.start_link( "benchS" )
{ :ok, _tidM } = SortedTtlList.start_link( "benchM" )
{ :ok, _tidL } = SortedTtlList.start_link( "benchL" )
{ :ok, tidMP } = SortedTtlList.start_link( "benchMP", true )
{ :ok, tidLP } = SortedTtlList.start_link( "benchLP", true )

size_s = 100
size_m = 10_000
size_l = 100_000

# prepare list
IO.puts "prepare Small List: size: #{size_s}"
Enum.each( Enum.to_list( 1..size_s ), &( SortedTtlList.push( "benchS", "key#{&1}", &1, 60, "data#{&1}" ) ) )

IO.puts "prepare Medium List size: #{size_m}"
Enum.each( Enum.to_list( 1..size_m ), &( SortedTtlList.push( "benchM", "key#{&1}", &1, 60, "data#{&1}" ) ) )

IO.puts "prepare Large List size: #{size_l}"
Enum.each( Enum.to_list( 1..size_l ), &( SortedTtlList.push( "benchL", "key#{&1}", &1, 60, "data#{&1}" ) ) )

size_mp = SortedTtlList.size( tidMP )
if size_mp <= 0 do
	IO.puts "prepare Medium List Persisted size: #{size_m}"
	Enum.each( Enum.to_list( 1..size_m ), &( SortedTtlList.push( "benchMP", "key#{&1}", &1, 60, "data#{&1}" ) ) )
else
	IO.puts "use restored Medium Persisted List size: #{size_mp}"
end

size_lp = SortedTtlList.size( tidLP )
if size_lp <= 0 do
	IO.puts "prepare Large List Persisted size: #{size_l}"
	Enum.each( Enum.to_list( 1..size_l ), &( SortedTtlList.push( "benchLP", "key#{&1}", &1, 60, "data#{&1}" ) ) )
	SortedTtlList.backup( tidLP )
else
	IO.puts "use restored Large Persisted List size: #{size_l}"
end

IO.puts "run benchmark"
Benchee.run( %{
	"1.) .get/2" => fn( [ tbl, size ] ) ->
		i = :rand.uniform( size )
		SortedTtlList.get( tbl, "key#{i}" )
	end,
	"2.) .list/2 forward" => fn( [ tbl, _size ] ) ->
		SortedTtlList.list( tbl, true )
	end,
	"3.) .list/2 reverse" => fn( [ tbl, _size ] ) ->
		SortedTtlList.list( tbl, false )
	end,
	# "4.) .push/5" => fn( [ tbl, size ] ) ->
	# 	i = :rand.uniform( size * 2 )
	# 	SortedTtlList.push( tbl, "key#{i}", i, 60, "data#{i}" )
	# end,
	#"pushdata"    => fn -> Enum.each(list, push) end,
},
	time: 2,
	console: [
		comparison: false,
		unit_scaling: :none
	],
	inputs: %{
		"A) Small List (#{ size_s })" => [ "benchS", size_s ],
		"B) Medium List (#{ size_m })" => [ "benchM", size_m ],
		"C) Large List (#{ size_l })" => [ "benchL", size_l ],
		"D) Medium Persisted List (#{ size_m })" => [ "benchMP", size_m ],
		"E) Large Persisted List (#{ size_l })" => [ "benchLP", size_l ],
	}
)
