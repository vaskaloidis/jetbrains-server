module Jetbrains
  class TunnelServer
    def self.start_ngrok
      puts '--ngrok Flag Set'
      puts ('[NGROK] tunneling at ' + Ngrok::Tunnel.start(addr: 'localhost:9123')).green
      ngrok_url = Ngrok::Tunnel.ngrok_url_https
      `echo '#{ngrok_url}' | pbcopy`
      puts "Ngrok HTTPS URL #{ngrok_url} - Added to clipbard!".blue
      puts "Jetbrains Activation Server: #{ngrok_url}".green
      tunnel_running = true if Ngrok::Tunnel.running?
    end

    def self.stop_ngrok
      # Stop Ngrok
    end

    def self.start_local_tunnel
      https_regex = /(https)+.+(localtunnel.me)/
      puts 'Using Localtunnel. Optionally --localtunnel flag'
      # [ -e file ] && rm file
      # puts `[ -e .9213.tunnel ] && rm .9123.tunnel`
      # puts `[ -e .3001.tunnel ] && rm .3001.tunnel`
      command1 = `lt --port 9123 &>'9123.tmp' &`
      command2 = `lt --port 3001 &>'3001.tmp' &`
      url1 = `cat 9123.tmp`
      puts "Tunnel 1 #{url1}:9123".green if url1 =~ https_regex
      url2 = `cat 3001.tmp`
      if url2 =~ https_regex
        puts "Tunnel 2:#{url2}:3001".green
        url2 += '/github/hook/commit'
        ENV['GITHUB_PUSH_HOOK'] = url2
        if ENV['GITHUB_PUSH_HOOK'] == url2
          puts 'Succesfully saved Tunnel2 to GITHUB_PUSH_HOOK to Env'.green
        else
          puts 'Unabled to save GITHUB_PUSH_HOOK to Env'.red
        end
      end
      `echo '#{url1}' | pbcopy`
      'Saved Tunnel 1 to Clipboard'
      tunnel_running = true
      `rm 9123.tmp`
      `rm 3001.tmp`
    end

    def self.stop_local_tunnel
      # Stop localtunnel
    end
    end
end
