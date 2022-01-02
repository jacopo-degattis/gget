require "uri"
require "json"
require "net/http"
require "base64"

class Git
    def initialize(apiUrl = "https://api.github.com")
        @apiUrl = apiUrl
        @current_download_folder = "downloads"
        _create_dir(@current_download_folder)
    end

    def _create_dir(path)
        if !Dir.exist?(path)
            Dir.mkdir(path)
        end
    end

    def parse_uri(repo)
        repo_info, repo_path = repo.path.split("/tree/")
        owner, repo_name = repo_info.split("/")[1..-1]
        path_without_branch = repo_path.split("/")[1..-1].join("/")
        api_uri = "#{@apiUrl}/repos/#{owner}/#{repo_name}/contents/#{path_without_branch}"
        return URI.parse(api_uri), repo_name
    end

    def _download_resource(resource_data)
        puts "Resource, #{resource_data}"
    end

    def _handle_resource(resource, repo_name)
        if resource['type'] == "dir"
            current_path = "#{@current_download_folder}/#{repo_name}/#{resource['name']}"
            _create_dir(current_path)
            @current_download_folder += resource['name']
            Dir.chdir(current_path) do
                # TODO: absolutely improve, create function just to handle http requests
                uri = URI.parse(resource['git_url'])
                response = Net::HTTP.get_response(uri)
                data = JSON.parse(response.body)

                data['tree'].each do |res|                
                    _handle_resource(res, repo_name)
                end
            end
        elsif resource['type'] == 'blob'
            filename = resource['path']
            uri = URI.parse(resource['url'])
            info = Net::HTTP.get_response(uri)
            b64_data = JSON.parse(info.body)['content']
            byte_data = Base64.decode64(b64_data)
            new_file = File.open(filename, "w") { |f| f.write(byte_data) }
        elsif resource['type'] == 'tree'
            path = resource['path']
            current_path = "#{@current_download_folder}/#{repo_name}/#{resource['name']}"
            # _create_dir(current_path)
            # Dir.chdir(current_path) do
            #     uri = URI.parse(resource['git_url'])
            #     response = Net::HTTP.get_response(uri)
            #     data = JSON.parse(response.body)

            #     data['tree'].each do |res|                
            #         _handle_resource(res, repo_name)
            #     end
            # end
        end
    end

    def get_repo(repo)
        repo_uri = URI.parse(repo)
        repo_api_uri, repo_name = parse_uri(repo_uri)
        puts "#{repo_name}"
        response = Net::HTTP.get_response(repo_api_uri)
        data = JSON.parse(response.body)
        _create_dir("#{@current_download_folder}/#{repo_name}")

        data.each do |resource|
            _handle_resource(resource, repo_name)
        end
    end
end