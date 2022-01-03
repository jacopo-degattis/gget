require_relative "git.rb"

t = Git.new
t.get_repo("https://github.com/jacopo-degattis/playlist_converter/tree/master/libs")