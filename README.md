# Sorted TTL List

[![Travis Build Status](https://img.shields.io/travis/mpneuried/sorted_ttl_list.svg)](https://travis-ci.org/mpneuried/sorted_ttl_list)
[![Windows Tests](https://img.shields.io/appveyor/ci/mpneuried/sorted-ttl-list.svg?label=WindowsTest)](https://ci.appveyor.com/project/mpneuried/sorted-ttl-list)
[![Coveralls Coverage](https://img.shields.io/coveralls/mpneuried/sorted_ttl_list.svg)](https://coveralls.io/github/mpneuried/sorted_ttl_list)

[![Hex.pm Version](https://img.shields.io/hexpm/v/sorted_ttl_list.svg)](https://hex.pm/packages/sorted_ttl_list)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/mpneuried/sorted_ttl_list.svg?branch=master)](https://beta.hexfaktor.org/github/mpneuried/sorted_ttl_list)
[![Hex.pm](https://img.shields.io/hexpm/dt/sorted_ttl_list.svg?maxAge=2592000)](https://hex.pm/packages/sorted_ttl_list)

A ets based list with an expire feature. So you can push keys to the list that will expire after a gven time.
An example use case could be a user online list with additional data.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `sorted_ttl_list` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:sorted_ttl_list, "~> 1.0.0"}]
    end
    ```

  2. Ensure `sorted_ttl_list` is started before your application:

    ```elixir
    def application do
      [applications: [:sorted_ttl_list]]
    end
    ```

## Basic usage

### START

Create the table

```elixir
{ :ok, tid } = SortedTtlList.start_link( "my_tablename" )
```

Create the table with active backup/restore on terminate/load via dets.

```elixir
{ :ok, tid } = SortedTtlList.start_link( "my_tablename", true )
```

### PUSH / UPDATE

Add elements to the list or update existing keys

```elixir
{ "element_key", 1480592547, 1480592607, %{ additional: "data" } } = SortedTtlList.push( "my_tablename", "element_key", 1480592547, 60, %{ additional: "data" } )
```

### GET

get a single element by key

```elixir
{ "element_key", 1480592547, 1480592607, %{ additional: "data" } } = SortedTtlList.get( "my_tablename", "element_key" )
```

### LIST

get the sorted list

```elixir
[ { "another_key", 1337, 1480622607, %{ another: "data" } }, { "element_key", 1480592547, 1480592607, %{ additional: "data" } } ] = SortedTtlList.list( "my_tablename" )
```

or sorted fron high to low
```elixir
[ { "another_key", 1337, 1480622607, %{ another: "data" } }, { "element_key", 1480592547, 1480592607, %{ additional: "data" } } ] = SortedTtlList.list( "my_tablename", true )
```

### DELETE

delete a element

```elixir
:ok = SortedTtlList.list( "my_tablename", "element_key" )
```

### FLUSH

flush all data within a table

```elixir
:ok = SortedTtlList.flush( "my_tablename" )
```

### SIZE

get the size of the list

```elixir
2 = SortedTtlList.size( "my_tablename" )
```

### EXISTS

check of the list is started and the ets table exists

```elixir
true = SortedTtlList.exists( "my_tablename" )
false = SortedTtlList.exists( "nobody" )
```

### BACKUP

Manual backup of the ets table to a dets file.
If persistence is active this is also done on terminate

```elixir
:ok = SortedTtlList.backup( "my_tablename" )
```

## Benchmark

The run the benchmark call: 

```sh
MIX_ENV=test mix run bench/sorted_ttl_list_bench.exs
```

## Release History

|Version|Date|Description|
|:--:|:--:|:--|
|1.1.0|2016-12-08|added optional persistence via dets on load and terminate. There are also a new methods for manual backup `.backup/1` and to clear the whole table `.flush/1`. Added benchmarks |
|1.0.0|2016-12-08|breaking change: return of `push` is now the generated data `{ key, score, expire_ts, data }` instead of just an `:ok` |
|0.1.2|2016-12-01|removed io inspect|
|0.1.1|2016-12-01|added reverse option for list|
|0.1.0|2016-12-01|added `exists` method and optimized docs|
|0.0.1|2016-11-28|Minimal elixir version|
|0.0.1|2016-11-28|first alpha version ...|

## The MIT License (MIT)

Copyright © 2016 M. Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
