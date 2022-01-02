require "uri"
require "json"
require "net/http"
require "base64"
require 'fileutils'

class Git
    def initialize(apiUrl = "https://api.github.com")
        @apiUrl = apiUrl
        @current_download_folder = "downloads"
        _create_dir(@current_download_folder)
    end

    def _create_dir(path)
        puts "Creating #{path}"
        FileUtils.mkdir_p(path) unless File.exists?(path)
    end

    def parse_uri(repo)
        repo_info, repo_path = repo.path.split("/tree/")
        owner, repo_name = repo_info.split("/")[1..-1]
        path_without_branch = repo_path.split("/")[1..-1].join("/")
        api_uri = "#{@apiUrl}/repos/#{owner}/#{repo_name}/contents/#{path_without_branch}"
        return URI.parse(api_uri), repo_name
    end

    def _fetch(uri)
        url = URI.parse(uri)
        # Catch error, if response status != 200
        response = Net::HTTP.get_response(url)
        data = JSON.parse(response.body)
        return data
    end

    def _handle_dir(resource, repo_name)
        
        current_path = @current_download_folder += "/#{resource['name']}"
        puts "Current path #{current_path}"
        _create_dir(current_path)
        
        Dir.chdir(current_path) do

            data = _fetch(resource['git_url'])

            data['tree'].each do |res|                
                _handle_resource(res, repo_name)

            end
        end

        @current_download_folder.chomp(resource['name'])

    end

    def _handle_blob(resource, repo_name)
        data = _fetch(resource['url'])['content']
        byte_data = Base64.decode64(data)
        new_file = File.open(resource['path'], "w") { |f| f.write(byte_data) }
    end

    def _handle_tree(resource, repo_name)
        
        current_path = @current_download_folder += "/#{resource['path']}"
       
        puts "Current path #{current_path}"
        # FileUtils.mkdir_p("./downloads/myLinkedLists/lib/linkedlist")

        # _create_dir(current_path)
        
        # Dir.chdir(current_path) do

        #     data = _fetch(resource['url'])

        #     data['tree'].each do |res|                
        #         _handle_resource(res, repo_name)

        #     end
        # end

        # @current_download_folder.chomp(resource['name'])
        
    end
    
    def _handle_resource(resource, repo_name)
        case resource['type']
            when "dir"
                _handle_dir(resource, repo_name)
            when "blob"
                _handle_blob(resource, repo_name)  
            when "tree"
                _handle_tree(resource, repo_name)
        end
    end

    def get_repo(repo)
        repo_uri = URI.parse(repo)
        repo_api_uri, repo_name = parse_uri(repo_uri)
        response = Net::HTTP.get_response(repo_api_uri)
        data = JSON.parse(response.body)
        @current_download_folder += "/#{repo_name}"
        _create_dir("#{@current_download_folder}")

        data.each do |resource|
            _handle_resource(resource, repo_name)
        end
    end
end