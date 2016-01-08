require "watir-webdriver"
require "headless"
require "addressable/uri"
require "json"

ENV["TZ"] = "America/Los_Angeles"

def usage
  warn "USAGE: ruby #{$0} <file listing urls to remove>"
  exit 1
end

@url_list_file = ARGV.shift

if @url_list_file.nil? or @url_list_file == ""
  usage
end
@url_list_file = @url_list_file.strip

def random_sleep
  sleep rand(3..5)
end

def verify_credential
  json_file = File.join(File.dirname(__FILE__), "config.json")

  begin
    json = JSON.parse(File.read(json_file))
  rescue
    abort "Must provide config.json file. Please refer to README.md"
  end
  
  username = json["credential"]["username"]
  password = json["credential"]["password"]

  email_field = @browser.input(id: "Email")
  if email_field.present?
    email_field.send_keys(username)
    random_sleep
  end

  next_button = @browser.input(id: "next")
  if next_button.present?
    next_button.click
    random_sleep
  end

  password_field = @browser.input(id: "Passwd")
  if password_field.present?
    password_field.send_keys(password)
    random_sleep
  end

  signin_button = @browser.input(id: "signIn")
  if signin_button.present?
    signin_button.click
    random_sleep
  end
end

def submit_deindex(url_to_remove)
  url_to_remove = url_to_remove.strip
  url_to_remove = "http://" + url_to_remove unless url_to_remove =~ /^http/  
  url_scheme = Addressable::URI.parse(url_to_remove).scheme
  url_site = Addressable::URI.parse(url_to_remove).host
  url_site = "www." + url_site unless url_site =~ /^www\./
  url_path = Addressable::URI.parse(url_to_remove).path
  url_to_remove = url_scheme + "://" + url_site + url_path

  now_epoch = Time.now.strftime("%s").to_i
  now_timestamp = Time.at(now_epoch).strftime("%Y-%m-%d %H:%M:%S")

  status = nil
  
  case url_path
  when "/"
    status = "Request to remove a ROOT path is forbidden!"
  when ""
    status = "Request to remove an EMPTY path is forbidden!"
  end

  num_levels = url_path.split("/").compact.reject { |c| c.empty? }.count
  case num_levels
  when 1
    status = "Request to remove a top level URL is forbidden!"
  end

  unless status.nil?
    puts "#{now_timestamp}\t#{url_to_remove}\t#{status}"
    STDOUT.flush    
  else
    site_url = url_scheme + "://" + url_site
    @browser.goto "https://www.google.com/webmasters/tools/removals-request?hl=en&siteUrl=#{site_url}/&urlt=#{url_to_remove}"

    now_epoch = Time.now.strftime("%s").to_i
    now_timestamp = Time.at(now_epoch).strftime("%Y-%m-%d %H:%M:%S")
    
    submit_button = @browser.input(id: "submit-button")
    submit_button.wait_until_present
    submit_button.click
    random_sleep

    status = @browser.span(class: /status-message-text/).text
    puts "#{now_timestamp}\t#{url_to_remove}\t#{status}"
    STDOUT.flush
  end
end

begin
  @browser = Watir::Browser.new :firefox
  @browser.window.maximize
  @browser.driver.manage.timeouts.implicit_wait = 30

  @browser.goto "https://www.google.com/webmasters/tools"
  random_sleep

  verify_credential

  File.read(@url_list_file).split(/\n/).each do |url_to_remove|
    submit_deindex(url_to_remove)
  end
ensure
  @browser.close
end



