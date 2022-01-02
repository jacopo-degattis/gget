require_relative "git.rb"

t = Git.new
t.get_repo("https://github.com/jacopo-degattis/myLinkedLists/tree/main/src")