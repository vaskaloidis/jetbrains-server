module Jetbrains
	# License Server
	  # Note: some (most?) products request //rpc/whatever.action instead of /rpc/whatever.action, so keep that in mind when porting to another framework
	  class LicenseServer < Sinatra::Base
	    # Prolongation-Period
	    # How long the ticket should last for before trying to renew it in MILLISECONDS. CrackAttackz chose 607875500, which is about 7 days. There doesn't immediately *seem* to be any problem using a higher value, but I haven't tested it
	    PROLONGATION_PERIOD = 607_875_500

	    # Startup
	    def self.run!(options = {})
	      tunnel_running = false
	      unless options[:localtunnel]
	        puts '--ngrok Flag Set'
	        puts ('[NGROK] tunneling at ' + Ngrok::Tunnel.start(addr: 'localhost:9123')).green
	        ngrok_url = Ngrok::Tunnel.ngrok_url_https
	        `echo '#{ngrok_url}' | pbcopy`
	        puts "Ngrok HTTPS URL #{ngrok_url} - Added to clipbard!".blue
	        puts "Jetbrains Activation Server: #{ngrok_url}".green
	        tunnel_running = true if Ngrok::Tunnel.running?
	      else
	        https_regex = /(https)+.+(localtunnel.me)/
	        puts 'Using Localtunnel. (--localtunnel flag)'
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
	      super(options)
	    end

	    helpers do
	      def signed_xml_response(message)
	        content_type :xml
	        format("<!-- %s -->\n%s", LicenseSigner.new.sign(message), message) # Products look for a signature in the first html comment. It also requres a space between the dashes and the signature
	      end

	      def log_ticket_action(type, override = {})
	        (settings.logger || logger).info(format('ticket #%i %s %s@%s for %s version %s', (params['ticketId'] || override['ticketId']), type, params['userName'], params['hostName'], ProductIdentifier.get_product_name_for_family_id(params['productFamilyId']), params['buildNumber'].split(' ')[0]))
	      end

	      def log_ticket_issued(ticket_id)
	        log_ticket_action('issued to', 'ticketId' => ticket_id)
	      end

	      def log_ticket_released
	        log_ticket_action('released by')
	      end

	      def log_ticket_prolonged
	        log_ticket_action('prolonged by')
	      end
	    end

	    # Obtain-Ticket Action
	    get '/rpc/obtainTicket.action' do
	      # example request: //rpc/obtainTicket.action?buildDate=20160721&buildNumber=2016.2.1+Build+PY-162.1628.8&clientVersion=2&hostName=desktop&machineId=53712acc-d332-47e8-9c40-63985c523e54&productCode=e8d15448-eecd-440e-bbe9-1e5f754d781b&productFamilyId=e8d15448-eecd-440e-bbe9-1e5f754d781b&salt=1471926280350&secure=false&userName=whatever&version=20160721&versionNumber=2000
	      # buildDate is obvious
	      # buildNumber contains the version as a string and an abbreviation of the product name but the latter isn't always accurate, DataGrip's is DB for instance
	      # clientVersion seems to be a client API version
	      # hostName - again, obvious
	      # machineId is a random uuid that's generated once then stored in Java's preferences as 'user_id_on_machine' in the 'jetbrains' node
	      # productFamilyId is the uuid of the product, and productCode is the same (included for legacy reasons, or because IDEA has community and ultimate versions?)
	      # salt is a unix timestamp of the current time, intended to prevent replay attacks
	      # secure is whether we're connecting over ssl/tls
	      # userName is obviously the user's username on the pc
	      # version is the product version as an integer
	      # versionNumber is unknown, the same as version on IDEA Ultimate but 2000 on PyCharm

	      ticket_id = rand(999_999_999) # This seems to be stored as a string or long so we need not worry about overflows but let's keep it small just to make it easier to read in our logs
	      xml = ['<ObtainTicketResponse>',
	             '  <message/>',
	             format('  <prolongationPeriod>%i</prolongationPeriod>', PROLONGATION_PERIOD),
	             '  <responseCode>OK</responseCode>',
	             format('  <salt>%i</salt>', params[:salt]),
	             format('  <ticketId>%i</ticketId>', ticket_id),
	             format("  <ticketProperties>licensee=%s\tlicenseType=0\t</ticketProperties>", params['userName']), # licenseType=0 I guess is floating, permenent activations were once supported so this is probably for legacy reasons
	             '</ObtainTicketResponse>'].join("\n")

	      log_ticket_issued(ticket_id)

	      signed_xml_response xml
	    end

	    # Prolong-Ticket action
	    #  Prolongs the ticket expiration by the ticket's original prolongation period (for several hours I thought I was missing a value in the response causing the product to set the "new prolongation period" to 0 and spam the server but it turns out my PROLONGATION_PERIOD was like 100 and I thought it was in seconds instead of milliseconds <img src="images/smileys/Yum.png" />)
	    get '/rpc/prolongTicket.action' do #
	      xml = ['<ProlongTicketResponse>',
	             '  <message></message>',
	             '  <responseCode>OK</responseCode>',
	             format('  <salt>%i</salt>', params[:salt]),
	             format('  <ticketId>%i</ticketId>', params['ticketId']),
	             '</ProlongTicketResponse>'].join("\n")

	      log_ticket_prolonged

	      signed_xml_response xml
	    end

	    # Release-Ticket action
	    # This is called when the product shuts down. The client doesn't seem to expect a response
	    get '/rpc/releaseTicket.action' do
	      # Request params are buildNumber, clientVersion, hostName, machineId, productCode, productFamilyId, salt, secure, and userName as explained above, plus ticketId which is the ticketId we assigned in obtainTicket.action
	      log_ticket_released
	    end

	    # Ping
	    # I'm not totally sure what this is used for, but I guess every 48hrs this is called to make sure the licensing server is still up
	    # TODO: document request parameters
	    get '/rpc/ping.action' do
	      xml = ['<PingResponse>',
	             '  <message></message>',
	             '  <responseCode>OK</responseCode>',
	             format('  <salt>%i</salt>', params[:salt]),
	             '</PingResponse>'].join("\n")

	      signed_xml_response xml
	    end

	    at_exit do
	      if Ngrok::Tunnel.running?
	        puts 'Attempting to stop Ngrok'.green
	        Ngrok::Tunnel.stop
	        puts 'Ngrok shutdown'.red
	      else
	        tunnel1s = `ps aux | grep '[n]ode /usr/local/bin/lt --port 3001' | awk '{print $2}'`
	        tunnel1s.strip!
	        pids = tunnel1s.split("\n")
	        tunnel2s = `ps aux | grep '[n]ode /usr/local/bin/lt --port 9123' | awk '{print $2}'`
	        tunnel2s.strip!
	        pids.concat(tunnel2s.split("\n"))
	        pids.collect { |p| puts p }
	        pids.collect { |pid| puts `kill "#{pid}"`.green }
	      end
	    end


	end
end