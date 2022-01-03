#! /usr/bin/ruby

require_relative "git.rb"

t = Git.new
t.get_repo("https://github.com/jacopo-degattis/trantor_library_bot/tree/main/src")