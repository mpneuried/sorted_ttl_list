defmodule SortedTtlList.Mixfile do
	use Mix.Project
	
	defp package do
		[
			files: [ "lib", "mix.exs", "README.md", "LICENSE" ],
			maintainers: [ "M. Peter" ],
			licenses: [ "MIT" ],
			links: %{ "GitHub" => "https://github.com/mpneuried/sorted_ttl_list" }
		]
	end
	
	defp description do
		"""
		A ets based list with an expire feature. So you can push keys to the list that will expire after a gven time.
		"""
	end
	
	def project do
		[
			app: :sorted_ttl_list,
			version: "0.1.1",
			elixir: "~> 1.3",
			build_embedded: Mix.env == :prod,
			start_permanent: Mix.env == :prod,
			deps: deps( ),
			package: package,
			description: description,
			docs: [ extras: [ "README.md" ], main: "readme" ],
			test_coverage: [ tool: ExCoveralls ]
		]
	end

	# Configuration for the OTP application
	#
	# Type "mix help compile.app" for more information
	def application do
		[
			applications: [
				:logger
			]
		]
	end

	# Dependencies can be Hex packages:
	#
	#	 {:mydep, "~> 0.3.0"}
	#
	# Or git/path repositories:
	#
	#	 {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
	#
	# Type "mix help deps" for more examples and options
	defp deps do
		[
			{ :dialyze, "~> 0.2", only: :dev },
			{ :credo, "~> 0.4", only: [ :dev, :test ] },
			{ :excoveralls, "~> 0.4", only: [ :dev, :test ] },
			{ :earmark, ">= 0.0.0", only: [ :docs, :dev ] },
			{ :ex_doc, ">= 0.0.0", only: [ :docs, :dev ] }
		]
	end
end
