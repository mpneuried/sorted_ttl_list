# Sorted TTL List

[![Travis Build Status](https://img.shields.io/travis/mpneuried/sorted_ttl_list.svg)](https://travis-ci.org/mpneuried/sorted_ttl_list)
[![Windows Tests](https://img.shields.io/appveyor/ci/mpneuried/sorted-ttl-list.svg?label=WindowsTest)](https://ci.appveyor.com/project/mpneuried/sorted-ttl-list)
[![Coveralls Coverage](https://img.shields.io/coveralls/mpneuried/sorted_ttl_list.svg)](https://coveralls.io/github/mpneuried/sorted_ttl_list)

[![Hex.pm Version](https://img.shields.io/hexpm/v/sorted_ttl_list.svg)](https://hex.pm/packages/sorted_ttl_list)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/mpneuried/sorted_ttl_list.svg?branch=master)](https://beta.hexfaktor.org/github/mpneuried/sorted_ttl_list)
[![Hex.pm](https://img.shields.io/hexpm/dt/sorted_ttl_list.svg?maxAge=2592000)](https://hex.pm/packages/sorted_ttl_list)

A ets based list with an expire feature. So you can push keys to the list that will expire after a gven time.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `sorted_ttl_list` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:sorted_ttl_list, "~> 0.1.0"}]
    end
    ```

  2. Ensure `sorted_ttl_list` is started before your application:

    ```elixir
    def application do
      [applications: [:sorted_ttl_list]]
    end
    ```
