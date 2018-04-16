module ChinarMarvel
  class Client
    include HTTParty
    base_uri 'http://gateway.marvel.com'
    attr_accessor :public_key, :private_key

    PAGE_SIZE = 10
    PAGE_NUM = 1

    class InvalidDataError < StandardError; end

    def initialize(options = {})
      @public_key = options[:public_key] || ENV["MARVEL_PUBLIC_KEY"]
      @private_key = options[:private_key] || ENV["MARVEL_PRIVATE_KEY"]
    end

    def characters(options = {})
      page_hash = paginate(options)
      response = fetch_response("/v1/public/characters", page_hash)
      parse_response(response)
    end

    def character(character_id)
      response = fetch_response("/v1/public/characters/#{character_id}")
      parse_response(response)
    end

    private

    def params(additional_params = {})
      base_hash = { :apikey => public_key, :ts => ts, :hash => digest }
      additional_params.merge(base_hash)
    end

    def digest
      Digest::MD5.hexdigest("#{ts}#{private_key}#{public_key}")
    end

    def ts
      begin
        Time.now.to_i
      end
    end

    def paginate(options)
      return {} if options[:paginate] == false
      page_num = options[:page_num] || PAGE_NUM
      page_size = options[:page_size] || PAGE_SIZE
      {offset: (page_num-1)*page_size, limit: page_size}
    end

    def fetch_response(endpoint, options = {})
      handle_timeouts do      
        self.class.get(endpoint, query: params(options))
      end
    end

    def parse_response(response)
      begin
        parsed_res = JSON.parse(response.body)
      rescue => e
        {status: "error", message: e.message}
      end
    end

    def handle_timeouts
      begin
        yield
      rescue Net::OpenTimeout, Net::ReadTimeout
        {status: "error", message: "Timedout"}
      end
    end    

  end
end