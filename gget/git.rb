require "uri"
require "json"
require "net/http"
require "base64"
require 'fileutils'

class Git
    def initialize(api_url = "https://api.github.com")
        @api_url = api_url
        @current_download_folder = "downloads"
        _create_dir(@current_download_folder)
    end

    def _create_dir(path)
        FileUtils.mkdir_p(path) unless File.directory?(path)
    end

    def _parse_nested_uri(repo)
        repo_info, repo_path = repo.path.split("/tree/")
        owner, repo_name = repo_info.split("/")[1..-1]
        path_without_branch = repo_path.split("/")[1..-1].join("/")
        api_uri = "#{@api_url}/repos/#{owner}/#{repo_name}/contents/#{path_without_branch}"
        return URI.parse(api_uri), repo_name
    end

    def _parse_unnested_uri(repo)
        owner, name = repo.to_s.split("/")[-2..-1]
        api_uri = "#{@api_url}/repos/#{owner}/#{name}/contents/"
        return URI.parse(api_uri), name
    end

    def parse_uri(repo)
        case repo.to_s.include?("tree")
            when true
                uri, name = _parse_nested_uri(repo)
            when false
                uri, name = _parse_unnested_uri(repo)
        end

        return uri, name
    end

    def _fetch(uri)
        url = URI.parse(uri)
        response = Net::HTTP.get_response(url)
        case response
            when Net::HTTPSuccess
                data = JSON.parse(response.body)
                return data
            else
                raise Exception.new "ERROR: An error occurred while fetching: #{uri}"
        end
    end

    def _fetch_raw(uri)
        url = URI.parse(uri)
        response = Net::HTTP.get_response(url)
        case response
            when Net::HTTPSuccess
                return response.body
            else
                raise Exception.new "ERROR: An error occurred while fetching: #{uri}"
        end
    end

    def _handle_dir(resource, repo_name)
        
        current_path = "#{@current_download_folder}/#{resource['name']}"
        _create_dir(current_path)

        Dir.chdir(current_path) do

            data = _fetch(resource['git_url'])

            data['tree'].each do |res|                
                _handle_resource(res, repo_name)

            end
        end

        @current_download_folder.chomp("/#{resource['name']}")

    end

    def _handle_blob(resource, repo_name)
        data = _fetch(resource['url'])['content']
        byte_data = Base64.decode64(data)
        new_file = File.open(resource['path'], "w") { |f| f.write(byte_data) }
    end

    def _handle_tree(resource, repo_name)
        
        current_path = "#{resource['path']}"
       
        _create_dir(current_path)
        
        Dir.chdir(current_path) do

            data = _fetch(resource['url'])

            data['tree'].each do |res|                
                _handle_resource(res, repo_name)

            end
        end

        @current_download_folder.chomp(resource['name'])
        
    end

    def _handle_file(resource, repo_name)
        data = _fetch_raw(resource['download_url'])

        file_path = "#{@current_download_folder}/"

        Dir.chdir(file_path) do
            new_file = File.open(resource['name'], "w") { |f| f.write(data) }
        end
    end
    
    def _handle_resource(resource, repo_name)
        case resource['type']
            when "dir"
                _handle_dir(resource, repo_name)
            when "blob"
                _handle_blob(resource, repo_name)  
            when "tree"
                _handle_tree(resource, repo_name)
            when "file"
                _handle_file(resource, repo_name)
        end
    end

    def get_repo(repo)
        repo_api_uri, repo_name = parse_uri(repo)
        response = Net::HTTP.get_response(repo_api_uri)
        data = JSON.parse(response.body)
        @current_download_folder += "/#{repo_name}"
        _create_dir("#{@current_download_folder}")

        data.each do |resource|
            _handle_resource(resource, repo_name)
        end
    end
end