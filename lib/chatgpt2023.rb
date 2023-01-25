#!usr/bin/env ruby

# file: chatgpt2023.rb

require 'net/http'
require 'uri'
require 'json'
require 'down'


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
    
    @apiurl = "https://api.openai.com/v1"
    
    raise 'You must supply an API key!' unless apikey
    @apikey, @debug = apikey, debug
    
  end
  
  def completions(s, temperature: 0, max_tokens: 7)
    r = self.go_completions(s, temperature: temperature, 
                            max_tokens: max_tokens)
    r[:choices]
  end
  
  def completion(s)
    self.go_completions(s).first[:text].strip
  end
  
  alias complete completion
  
  def edits(s, s2)
    r = self.go_edits(s, s2)
  end
  
  def images(s)
    self.go_images_generations(s)
  end
  
  def image(s)
    r = self.images(s)
    img = r[:data].first[:url]    
    Down.download(img)
  end  
  
  alias imagine image
  
  def images_edit(s, image, mask: nil)
    self.go_images_edits(s, image, mask: mask)
  end
  
  private

  def go_completions(s, temperature: 0, max_tokens: 7)

    h = {
      "model" => 'text-davinci-003',
      "prompt" => s,
      "temperature" => temperature,
      "max_tokens" => max_tokens
    }    
    
    submit('completions', h)    
    
  end
  
  def go_edits(s, s2)

    h = {
      "model" => 'text-davinci-edit-001',
      "input" => s,
      "instruction" => s2
    }
    
    submit('edits', h)
    
  end
  
  def go_images_generations(s, n: 1, size: '1024x1024')
    
    h = {
      "prompt" => s,
      "n" => n,
      "size" => size
    }
    
    submit('images/generations', h)
    
  end
  
  def go_images_edits(s, image, mask: nil, n: 1, size: '1024x1024')
    
    h = {
      "image" => image,
      "prompt" => s,
      "n" => n,
      "size" => size
    }
    
    h['mask'] = mask if mask
    
    submit('images/edits', h)
    
  end  
  
  def submit(uri, h)
        
    uri = URI.parse(@apiurl + '/' + uri)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = 'Bearer ' + @apikey
        
    puts 'h: ' + h.inspect if @debug
    request.body = JSON.dump(h)

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    
    JSON.parse(response.body, symbolize_names: true)
  end
  
end
