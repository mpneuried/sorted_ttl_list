defmodule SortedTtlListTest do
	@moduledoc """
	General test
	"""
	
	use ExUnit.Case
	doctest SortedTtlList

	alias SortedTtlList, as: Stl

	test "add elements to the table" do
		Stl.start_link( "testA", false )
		Stl.start_link( "testB" )
		
		Stl.push( "testA", "aaa", 1, 60, %{ a: 123 } )
		Stl.push( "testA", "bbb", 10, 60, %{ b: 234 } )
		
		Stl.push( "testB", "zzz", 23, 60, %{ z: 987 } )
		
		{ "aaa", 1, _, %{ a: 123 } } = Stl.get( "testA", "aaa" )
		
	 	[ { "aaa", 1, _, %{ a: 123 } }, { "bbb", 10, _, %{ b: 234 } } ] = Stl.list( "testA" )
		
		Stl.push( "testA", "ccc", 5, 60, %{ c: 345 } )
		Stl.push( "testB", "yyy", 13, 60 )
		
		[ { "aaa", 1, _, %{ a: 123 } }, { "ccc", 5, _, %{ c: 345 } }, { "bbb", 10, _, %{ b: 234 } } ] = Stl.list( "testA" )
		
		[ { "yyy", 13, _, nil }, { "zzz", 23, _, %{ z: 987 } } ] = Stl.list( "testB" )
		
		assert Stl.size( "testA" ) == 3
		assert Stl.size( "testB" ) == 2
	end
	
	test "add elements to a non started table" do
		{ :noproc, _meta } = catch_exit( Stl.push( "testX", "aaa", 1, 60, %{ a: 123 } ) )
		{ :noproc, _meta } = catch_exit( Stl.list( "testX" ) )
	end
	
	test "key expire" do
		Stl.start_link( "testEx" )
		
		Stl.push( "testEx", "aaa", 1, 5, %{ a: 123 } )
		Stl.push( "testEx", "bbb", 10, 10, %{ b: 234 } )
		Stl.push( "testEx", "ccc", 5, 1, %{ c: 345 } )
		Stl.push( "testEx", "ddd", 23, 10, %{ d: 456 } )
		
		[ { "aaa", 1, _, %{ a: 123 } }, { "ccc", 5, _, %{ c: 345 } }, { "bbb", 10, _, %{ b: 234 } }, { "ddd", 23, _, %{ d: 456 } } ] = Stl.list( "testEx" )
		[ { "ddd", 23, _, %{ d: 456 } }, { "bbb", 10, _, %{ b: 234 } }, { "ccc", 5, _, %{ c: 345 } }, { "aaa", 1, _, %{ a: 123 } } ] = Stl.list( "testEx", true )
		
		IO.puts "\nA: wait for 3 sec. until key 'ccc' expires"
		:timer.sleep( 3000 )
		
		[ { "aaa", 1, _, %{ a: 123 } }, { "bbb", 10, _, %{ b: 234 } }, { "ddd", 23, _, %{ d: 456 } } ] = Stl.list( "testEx" )
		
		IO.puts "\nB: wait for 4 sec. until key 'aaa' expires"
		:timer.sleep( 4000 )
		
		Stl.push( "testEx", "ddd", 1, 5, %{ d: 4567 } )
		
		[ { "ddd", 1, _, %{ d: 4567 } }, { "bbb", 10, _, %{ b: 234 } } ] = Stl.list( "testEx" )
		[ { "bbb", 10, _, %{ b: 234 } }, { "ddd", 1, _, %{ d: 4567 } } ] = Stl.list( "testEx", true )
		{ "bbb", 10, _, %{ b: 234 } } = Stl.get( "testEx", "bbb" )
		assert Stl.get( "testEx", "aaa" ) == nil
		
		# reset the ttl of the `ddd` element
		Stl.push( "testEx", "ddd", 13, 5, %{ d: 456 } )
		{ "bbb", 10, _, %{ b: 234 } } = Stl.get( "testEx", "bbb" )
		
		IO.puts "\nC: wait for 4 sec. until key 'bbb' expires"
		:timer.sleep( 4000 )
		
		assert Stl.get( "testEx", "bbb" ) == nil
		assert Stl.size( "testEx" ) == 1
		
		[ { "ddd", 13, _, %{ d: 456 } } ] = Stl.list( "testEx" )
		
		:timer.sleep( 2000 )
		
		assert Stl.get( "testEx", "ddd" ) == nil
		assert Stl.size( "testEx" ) == 0
		
		[ ] = Stl.list( "testEx" )
		
	end
	
	test "persistante table test" do
		Stl.start_link( "testPersistant", true )
		
		# started with pre populated table
		presize = Stl.size( "testPersistant" )
		if presize > 0 do
			IO.puts "found presited data size: #{ presize }"
		end
		assert presize in [ 0, 3 ]
		
		:ok = Stl.flush( "testPersistant" )
		
		Stl.push( "testPersistant", "aaa", 1, 60, %{ a: 123 } )
		Stl.push( "testPersistant", "bbb", 10, 60, %{ b: 234 } )
		
		
		{ "aaa", 1, _, %{ a: 123 } } = Stl.get( "testPersistant", "aaa" )
		
	 	[ { "aaa", 1, _, %{ a: 123 } }, { "bbb", 10, _, %{ b: 234 } } ] = Stl.list( "testPersistant" )
		
		Stl.push( "testPersistant", "ccc", 5, 60, %{ c: 345 } )
		
		[ { "aaa", 1, _, %{ a: 123 } }, { "ccc", 5, _, %{ c: 345 } }, { "bbb", 10, _, %{ b: 234 } } ] = Stl.list( "testPersistant" )
		
		
		assert Stl.size( "testPersistant" ) == 3
	end
	
end
