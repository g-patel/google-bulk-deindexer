require "sinatra"
require "tilt/erb"
require "nokogiri"
require "addressable/uri"
require "json"
require "gmail"

ENV["TZ"] = "America/Los_Angeles"
config_file = File.join(File.dirname(__FILE__), "config.json")
begin
  $json = JSON.parse(File.read(config_file))
rescue
  abort "Must provide config.json file. Please refer to README.md"
end

get "/" do
  redirect "/deindex"
end

get "/deindex" do
  erb :deindex
end

post "/" do
  redirect "/deindex"
end

post "/deindex" do
  # job in a separate thread
  deindex_job = fork do
    # wait if other job is running
    while %x[ps -ef | grep 'ruby [d]eindex.rb' | wc -l].strip.to_i > 0
      sleep 15
    end
    
    now_epoch = Time.now.strftime("%s").to_i
    now_timestamp = Time.at(now_epoch).strftime("%Y-%m-%d %H:%M:%S")
    input_file = "urls_to_remove.txt.#{now_epoch}"

    # turn in the url list in the text area into a file
    File.open(input_file, "w") do |f|
      f.write params["urls_to_remove"]
    end

    # run the deindexer
    @result = %x[ruby deindexer_cmdline.rb #{input_file}].split(/\n/)

    File.unlink(input_file)
    
    # save to CSV
    data_dir = File.join(File.dirname(__FILE__), "data")
    Dir.mkdir(data_dir) unless Dir.exist?(data_dir)
    history_file = File.join(data_dir, "history.tsv")
    history_tsv = File.open(history_file,"a")
    
    @result.each do |line|
      local_timestamp = line.scan(%r[(.+?)\t(.+?)\t(.+?)$]).flatten[0].strip
      url = line.scan(%r[(.+?)\t(.+?)\t(.+?)$]).flatten[1].strip
      status = line.scan(%r[(.+?)\t(.+?)\t(.+?)$]).flatten[2].strip
      history_tsv.puts "#{local_timestamp}\t#{url}\t#{status}"
    end

    history_tsv.close

    $result = @result
    
    # email the status
    Gmail.connect($json["credential"]["username"], $json["credential"]["password"]) do |gmail|
      gmail.deliver do
        send_to = $json["mailto"].join(", ")
        to send_to
        
        subject "Google Bulk Deindex Request submitted at #{now_timestamp}"

        html_part do
          content_type 'text/html; charset=UTF-8'

          body_string = "<html>"
          body_string += "<head><style>table, th, td { border: 1px solid black; }</style></head>"
          body_string += "<body>"
          body_string += "<h3>Submitted at: #{now_timestamp} PT</h3>"
          body_string += "<br>"
          body_string += "<table>"
          body_string += "<tr><th>Timestamp (PT)</th><th>URL</th><th>Status</th></tr>" # header

          $result.each do |line|
            local_timestamp = line.scan(%r[(.+?)\t(.+?)\t(.+?)$]).flatten[0].strip
            url = line.scan(%r[(.+?)\t(.+?)\t(.+?)$]).flatten[1].strip
            status = line.scan(%r[(.+?)\t(.+?)\t(.+?)$]).flatten[2].strip
            body_string += "<tr><th>#{local_timestamp}</th><th>#{url}</th><th>#{status}</th></tr>"
          end
          
          body_string += "</table>"
          body_string += "<br>"
          body_string += "</body>"
          body_string += "</html>"

          body body_string
        end
      end
    end
  end

  # nohup
  Process.detach(deindex_job)

  # message to display right away
  @post_message = "The removal request has been put into the queue. An email will be sent to #{$json['mailto'].join(', ')}"

  erb :deindex
end
