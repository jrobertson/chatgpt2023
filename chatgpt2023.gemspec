Gem::Specification.new do |s|
  s.name = 'chatgpt2023'
  s.version = '0.4.0'
  s.summary = 'A ChatGPT API wrapper. #experimental'
  s.authors = ['James Robertson']
  s.files = Dir["lib/chatgpt2023.rb"]
  s.add_runtime_dependency('down', '~> 5.4', '>=5.4.0')
  s.add_runtime_dependency('dynarex-daily', '~> 0.7', '>=0.7.0')
  s.signing_key = '../privatekeys/chatgpt2023.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/chatgpt2023'
end
