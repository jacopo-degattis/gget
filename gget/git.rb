require "net/http"
require "uri"

class Git
    def initialize(apiUrl = "https://api.github.com")
        @apiUrl = apiUrl
    end

    def parse_uri(repo)
        repo_info, repo_path = repo.path.split("/tree/")
        owner, repo_name = repo_info.split("/")[1..-1]
        path_without_branch = repo_path.split("/")[1..-1].join("/")
        api_uri = "#{@apiUrl}/repos/#{owner}/#{repo_name}/contents/#{path_without_branch}"
        return URI.parse(api_uri)
    end

    def get_repo(repo)
        repo_uri = URI.parse(repo)
        repo_api_uri = parse_uri(repo_uri)
        res = Net::HTTP.get_response repo_api_uri
        puts "#{res.body}"
    end
end