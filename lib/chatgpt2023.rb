#!usr/bin/env ruby

# file: chatgpt2023.rb

require 'net/http'
require 'uri'
require 'json'


# description: 1st experiment at playing with the ChatGPT API.

# 1. In order to use this gem you will need to sign up for a 
# ChatGPT account at https://openai.com/

# 2. To retrieve your API key, log into you account, click on 
# your profile and select *view API keys*

# 3. It's recommened you test the API using the Curl example as shown below:
#
#  curl https://api.openai.com/v1/completions \
#  -H "Content-Type: application/json" \
#  -H "Authorization: Bearer YOUR_API_KEY" \
#  -d '{"model": "text-davinci-003", "prompt": "Say this is a test", "temperature": 0, "max_tokens": 7}'

# ChatGpt documentation: https://beta.openai.com/docs/introduction/overview

# Usage:
#  require 'chatgpt2023'
#  
#  chat = ChatGpt2023.new(apikey: 'YOUR-API-KEY')
#  chat.completion 'Say this is a test'
#  #=> This is indeed a test 

class ChatGpt2023
  
  def initialize(apikey: nil, debug: false)
    
    @apiurl = "https://api.openai.com/v1/completions"
    raise 'You must supply an API key!' unless apikey
    @apikey, @debug = apikey, debug
    
  end
  
  def completions(s)
    r = self.submit(s)
    r[:choices]
  end
  
  def completion(s)
    self.completions(s).first[:text].strip
  end
  
  alias complete completion

  def submit(promptx='Say this is a test', prompt: promptx, type: :completions)
    
    uri = URI.parse(@apiurl)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = 'Bearer ' + @apikey
    
    model = {completions: 'text-davinci-003'}
    
    request.body = JSON.dump({
      "model" => model[type],
      "prompt" => prompt,
      "temperature" => 0,
      "max_tokens" => 7
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    
    JSON.parse(response.body, symbolize_names: true)
  end
  
end
