#!usr/bin/env ruby

# file: chatgpt2023.rb

require 'net/http'
require 'uri'
require 'json'
require 'down'
require 'dynarex-daily'


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
# ChatGpt web page: https://chat.openai.com/chat

# Usage:
#  require 'chatgpt2023'
#  
#  chat = ChatGpt2023.new(apikey: 'YOUR-API-KEY')
#  chat.completion 'Say this is a test'
#  #=> This is indeed a test 

class ChatGpt2023Error < Exception
end

class ChatGpt2023
  
  attr_accessor :assistant_recent
  
  def initialize(apikey: nil, attempts: 1, debug: false)
    
    @apiurl = "https://api.openai.com/v1"
    
    raise 'You must supply an API key!' unless apikey
    @apikey, @attempts, @debug = apikey, attempts, debug
    @assistant_recent = nil
    
  end
  
  
  # CURL example
  # curl https://api.openai.com/v1/chat/completions \
  # -H 'Content-Type: application/json' \
  # -H 'Authorization: Bearer YOUR_API_KEY' \
  # -d '{
  # "model": "gpt-3.5-turbo",
  # "messages": [{"role": "user", "content": "Hello!"}]
  # }'
  
  # Ruby example

  # require 'chatgpt2023'

  # c = ChatGpt2023.new(apikey: YOUR_API_KEY)
  # r = c.chat 'who is Burt Reynolds?'
  # r2 = c.chat 'what age was he?'
  # r3 = c.chat 'did he have family?'  
  #
  
  def chat(s, temperature: 1, max_tokens: 3900)
    r = chats(s, temperature: temperature, max_tokens: max_tokens)
    return r if r.is_a?(Hash) 
    return {text: r.first[:message][:content].strip}
  end
  
  def chats(s=nil, messages: [], temperature: 1, max_tokens: 3900, n: 1)
    
    messages << @assistant_recent if @assistant_recent
    messages << {'role' => 'user', 'content' => s } if s
    r = go_chat(messages, temperature: temperature, 
                       max_tokens: max_tokens, n: n)        
    
    puts 'chat/completions r: ' + r.inspect if @debug
    
    if r[:error] then r
      r
    else
      @assistant_recent = r[:choices].first[:message]
      r[:choices]
    end
    
  end  
  
  # Example
  # c = ChatGpt2023.new(apikey: 'yourapikey')
  # s = '
  # # Ruby
  # # Ask the user for their name and say "Hello"
  # '
  # r = c.code_completions s, temperature: 0.2
  # puts r.first[:text]
  #
  def code_completions(s, temperature: 1, max_tokens: 32, n: 1)
    
    r = go_code(s, temperature: temperature, 
                       max_tokens: max_tokens, n: n)
    puts 'code r: ' + r.inspect if @debug
    r[:error] ? r : r[:choices]
    
  end

  def code_completion(s, temperature: 1, max_tokens: 32)
    r = code_completions(s, temperature: temperature, max_tokens: max_tokens)
    return r if r.is_a?(Hash) 
    return {text: r.first[:text].strip}
  end  
  
  def completions(s, temperature: 1, max_tokens: 32, n: 1)
    
    r = go_completions(s, temperature: temperature, 
                       max_tokens: max_tokens, n: n)
    puts 'completions r: ' + r.inspect if @debug
    r[:error] ? r : r[:choices]
    
  end
  
  def completion(s, temperature: 1, max_tokens: 32)
    r = completions(s, temperature: temperature, max_tokens: max_tokens)
    return r if r.is_a?(Hash) 
    return {text: r.first[:text].strip}
  end
  
  alias complete completion
  alias ask chat
  
  def edits(s, s2)
    r = go_edits(s, s2)
  end
  
  def images(s)
    go_images_generations(s)
  end
  
  def image(s)
    r = images(s)
    Down.download(r[:data].first[:url] )
  end  
  
  alias imagine image
  
  def images_edit(s, image, mask: nil)
    go_images_edits(s, image, mask: mask)
  end
  
  private
  
  def go_chat(messages=[], temperature: 0, max_tokens: 4096, n: 1)

    h = {      
      "model" => 'gpt-3.5-turbo',
      "messages" => messages,
      "temperature" => temperature,
      "max_tokens" => max_tokens,
      "n" => n
    }    
    
    submit('chat/completions', h)    
    
  end  
  
  def go_code(s, temperature: 0, max_tokens: 7, n: 1)

    h = {
      "model" => 'code-davinci-002',
      "prompt" => s,
      "temperature" => temperature,
      "max_tokens" => max_tokens,
      "n" => n
    }    
    
    submit('completions', h)    
    
  end  

  def go_completions(s, temperature: 0, max_tokens: 7, n: 1)

    h = {
      "model" => 'text-davinci-003',
      "prompt" => s,
      "temperature" => temperature,
      "max_tokens" => max_tokens,
      "n" => n
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
  
  def submit(uri2, h)
        
    uri = URI.parse(@apiurl + '/' + uri2)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = 'Bearer ' + @apikey
        
    puts 'h: ' + h.inspect if @debug
    request.body = JSON.dump(h)

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    attempts = 0
    
    begin
    
      attempts += 1
      
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      
      h = JSON.parse(response.body, symbolize_names: true)
      
      if h[:error] then
        puts 'warning:' + h[:error][:message] 
        sleep 5
      end
    
    end while h.has_key?(:error) and attempts < @attempts
        
    #raise ChatGpt2023Error, h[:error][:message].inspect if h.has_key? :error
    
    return h
  end
  
end

class CGRecorder <  ChatGpt2023
  
  attr_reader :index
  
  def initialize(apikey: nil, indexfile: 'cgindex.xml', 
                 logfile: 'chatgpt.xml', attempts: 1, debug: false)

    super(apikey: apikey, attempts: attempts, debug: debug)
    @dx = DynarexDaily.new filename: logfile, fields: %i(prompt result), 
        autosave: true, order: 'descending', debug: debug
    @index = Dynarex.new(indexfile, schema: 'entries[title]/entry(prompt, ' \
      + 'tags)', order: 'descending', autosave: true)
    title = 'ChatGPT prompt log'
    @index.title = title    
    
  end
  
  def code_completion(s, tags=nil, temperature: 1, max_tokens: 2000)
    
    r = super(s, temperature: temperature, max_tokens: max_tokens)    
    log(s, r[:text].strip, tags) unless r[:error]
    
    return r
    
  end   

  def completion(s, tags=nil, temperature: 1, max_tokens: 1000)
    
    r = super(s, temperature: temperature, max_tokens: max_tokens)
    puts 'CGRecorder inside completion: ' + r.inspect if @debug
    log(s, r[:text].strip, tags) unless r[:error]
    
    return r
    
  end
  
  alias complete completion
  alias ask completion  
  
  private
  
  def log(prompt, result, tags)
    
    @index.create({prompt: prompt, tags: tags})
    @dx.create({prompt: prompt, result: result})    
    
  end
end

class ChatAway
  
  # statement below used for debugging
  attr_reader :dx, :prompts
  
  def initialize(questions, apikey: nil, filepath: '/tmp/chatgpt', debug: false)
    
    @debug = debug
    
    FileUtils.mkdir_p filepath
    idxfile = File.join(filepath, 'index.xml')
    cgfile =  File.join(filepath, 'chatgpt.xml')

    puts 'questions: ' + questions.inspect if @debug
    @dx = case questions.class.to_s.to_sym
    when :Dynarex
      questions
    when :String
      questions.lines.length < 2 ? Dynarex.new(questions) : import(questions)
    end
    
    @chat = CGRecorder.new(apikey: apikey, indexfile: idxfile, 
                           logfile: cgfile, attempts: 5, debug: @debug)
    @prompts = @chat.index.all.map(&:prompt)
    
    @mode = nil
    
  end 
  
  def start()        
    
    @dx.all.map do |rx|
      
      puts 'rx: ' + rx.inspect if @debug
      
      #if (@prompts.include?(rx.prompt) and rx.redo != 'true') \
      #    or @mode != :import
      #  next 
      #end
      
      type = rx.type == 'code' ? :code_completion : :completion
      
      prompt = rx.prompt
      
      puts 'prompt: ' + prompt

      attempts = 0
      reply = nil
      
      begin
        
        r = @chat.method(type).call prompt
        
        puts 'r: ' + r.inspect if @debug
        
        if r[:error] then
          
          puts r[:error][:text]
          sleep 2
          attempts += 1
          
          redo if attempts < 4             
          
        else
          reply = r[:text]
        end
        
      rescue
        
        puts 'Something not working! ' + ($!).inspect
        sleep 2
        attempts += 1
        
        retry if attempts < 4 
        
      ensure
        
        reply ||= ''
        
      end
      
      sleep 2
      
      reply
        
    end    
    
  end
  
  private
  
  
  def import(s)

    @mode = :import
    puts 'inside import' if @debug
    
    header = '<?dynarex schema="prompts/entry(prompt, type, redo)" delimiter=" # "?>
--+ 
'

    s2 = header + s.strip.lines.map {|line| 'p: ' + line }.join("\n")

    Dynarex.new(s2)
    
  end   
  
end
