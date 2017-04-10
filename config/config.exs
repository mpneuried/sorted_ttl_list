# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :sorted_ttl_list,
	# the folder to save the dets files into. If not defined it'll use the project root folder
	folder: { :system, "SORTED_TTL_LIST_FOLDER", "" }
