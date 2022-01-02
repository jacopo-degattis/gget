require "uri"
require "json"
require "net/http"

class Git
    def initialize(apiUrl = "https://api.github.com")
        @apiUrl = apiUrl
        if !Dir.exist?("downloads")
            Dir.mkdir("downloads")
        end
    end

    def parse_uri(repo)
        repo_info, repo_path = repo.path.split("/tree/")
        owner, repo_name = repo_info.split("/")[1..-1]
        path_without_branch = repo_path.split("/")[1..-1].join("/")
        api_uri = "#{@apiUrl}/repos/#{owner}/#{repo_name}/contents/#{path_without_branch}"
        return URI.parse(api_uri)
    end

    def _download_resource(resource_data)
        puts "Resource, #{resource_data}"
    end

    def get_repo(repo)
        repo_uri = URI.parse(repo)
        repo_api_uri = parse_uri(repo_uri)
        response = Net::HTTP.get_response(repo_api_uri)
        data = JSON.parse(response.body)

        data.each do |resource|
            puts "Got, #{resource}"
        end
    end
end