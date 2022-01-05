#! /usr/bin/ruby
require "json"
require "net/http"
require_relative "git.rb"

VERSION = "0.1.0"
$AUTHENTICATED = false

def _print_help()
    helper = "gget #{VERSION}\nUtility to clone repo subfolders and files\n\nUSAGE:\n\tgget <repo_uri>\n\n\t-a Make authenticated requests\n\n"
    puts helper
end

def _check_and_save_creds()
    if File.exist?(".gget-cache")
        return
    end

    print "Github username: "
    username = STDIN.gets.strip
    print "Gitub token: "
    token = STDIN.gets.strip

    user_data = {
        "username" => username,
        "token" => token
    }
    
    # TODO: find a way to move .gget-cache file in user home folder
    File.open(".gget-cache", "w") { |f| f.write(user_data.to_json) }
    
end

def process_argv(option)
    git = Git.new
    case option
        when "--help"
            _print_help()
        when "-h"
            _print_help()
        when "-a"
            $AUTHENTICATED = true
            _check_and_save_creds()
        else
            uri = URI.parse(option)
            if uri.host.to_s != "github.com"
                raise Exception.new "ERROR: Invalid uri, domain must be github.com"
            end
            if !["http", "https"].include?(uri.scheme)
                raise Exception.new "ERROR: Invalid uri provided"
            end
            git.get_repo(URI.parse(option), $AUTHENTICATED)
    end
end

ARGV.each { |option| process_argv(option) }


# t.get_repo("https://github.com/jacopo-degattis/trantor_library_bot/tree/main/src")