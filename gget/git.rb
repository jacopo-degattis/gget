require "uri"
require "json"
require "net/http"
require "base64"
require 'fileutils'

class Git
    def initialize(api_url = "https://api.github.com")
        @api_url = api_url
        @current_download_folder = "downloads"
        @authenticated_headers = ""
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

    def _fetch(uri, authenticated)

        url = URI.parse(uri.to_s)
        req = Net::HTTP::Get.new(url)

        if authenticated
            req['Authorization'] = @authenticated_headers
        end

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        response = http.request(req)

        case response
            when Net::HTTPSuccess
                data = JSON.parse(response.body)
                return data
            else
                raise Exception.new "ERROR: An error occurred while fetching: #{uri}"
        end
    end

    def _fetch_raw(uri, authenticated)
        url = URI.parse(uri)
        req = Net::HTTP::Get.new(url)

        if authenticated
            req['Authorization'] = @authenticated_headers
        end

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        response = http.request(req)

        case response
            when Net::HTTPSuccess
                return response.body
            else
                raise Exception.new "ERROR: An error occurred while fetching: #{uri}"
        end
    end

    def _handle_dir(resource, repo_name, authenticated)
        
        current_path = "#{@current_download_folder}/#{resource['name']}"
        _create_dir(current_path)

        Dir.chdir(current_path) do

            data = _fetch(resource['git_url'], authenticated)

            data['tree'].each do |res|                
                _handle_resource(res, repo_name, authenticated)

            end
        end

        @current_download_folder.chomp("/#{resource['name']}")

    end

    def _handle_blob(resource, repo_name, authenticated)
        print("[!] Downloading #{resource['path']}\r")

        data = _fetch(resource['url'], authenticated)['content']
        byte_data = Base64.decode64(data)
        new_file = File.open(resource['path'], "w") { |f| f.write(byte_data) }
    end

    def _handle_tree(resource, repo_name, authenticated)

        current_path = "#{resource['path']}"
       
        _create_dir(current_path)
        
        Dir.chdir(current_path) do

            data = _fetch(resource['url'], authenticated)

            data['tree'].each do |res|                
                _handle_resource(res, repo_name)

            end
        end

        @current_download_folder.chomp(resource['name'])
        
    end

    def _handle_file(resource, repo_name, authenticated)
        print("[!] Downloading #{resource['name']}\r")
        data = _fetch_raw(resource['download_url'], authenticated)

        file_path = "#{@current_download_folder}/"

        Dir.chdir(file_path) do
            new_file = File.open(resource['name'], "w") { |f| f.write(data) }
        end
    end
    
    def _handle_resource(resource, repo_name, authenticated)
        case resource['type']
            when "dir"
                _handle_dir(resource, repo_name, authenticated)
            when "blob"
                _handle_blob(resource, repo_name, authenticated)  
            when "tree"
                _handle_tree(resource, repo_name, authenticated)
            when "file"
                _handle_file(resource, repo_name, authenticated)
        end
    end

    def _load_creds()
        if !File.exist?(".gget-cache")
            return
        end

        file = File.read(".gget-cache")
        user_data = JSON.parse(file)
        encoded_credentials = Base64.strict_encode64("#{user_data['username']}:#{user_data['token']}")
        @authenticated_headers = "Basic #{encoded_credentials}"
    end

    def get_repo(repo, authenticated=false)

        if authenticated
            _load_creds()
        end

        repo_api_uri, repo_name = parse_uri(repo)
        data = _fetch(repo_api_uri, authenticated)
        @current_download_folder += "/#{repo_name}"
        _create_dir("#{@current_download_folder}")

        data.each do |resource|
            _handle_resource(resource, repo_name, authenticated)
        end

        print("[+] Succesfully downloaded #{repo_name} !")
    end
end