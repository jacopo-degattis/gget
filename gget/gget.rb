require_relative "git.rb"

t = Git.new
t.get_repo("https://github.com/jacopo-degattis/flask-app-template/tree/main/backend")