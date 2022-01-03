#! /usr/bin/ruby
require "net/http"
require_relative "git.rb"

VERSION = "0.1.0"

def _print_help()
    helper = "gget #{VERSION}\nUtility to clone repo subfolders and files\n\nUSAGE:\n\tgget <repo_uri> "
    puts helper
end

def process_argv(option)
    git = Git.new
    case option
        when "--help"
            _print_help()
        when "-h"
            _print_help()
        else
            uri = URI.parse(option)
            if uri.host.to_s != "github.com"
                raise Exception.new "ERROR: Invalid uri, domain must be github.com"
            end
            if !["http", "https"].include?(uri.scheme)
                raise Exception.new "ERROR: Invalid uri provided"
            end
            git.get_repo(URI.parse(option))
    end
end

ARGV.each { |option| process_argv(option) }


# t.get_repo("https://github.com/jacopo-degattis/trantor_library_bot/tree/main/src")