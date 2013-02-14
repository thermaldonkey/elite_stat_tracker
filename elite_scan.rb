require_relative './zombies'
require_relative './elite'

if not File.exist?(File.expand_path(__FILE__+'/../elite.yml'))
  puts "Missing yaml config file! Check out elite.example.yml for further instructions."
  raise LoadError
else
  @creds = YAML.load(File.read(File.expand_path(__FILE__+'/../elite.yml')))
end

begin
  #Init new Elite object with credentials
  e = Elite.new @creds
  #Get logger
  log = e.log
  #Log in to CoD Elite
  m, home = e.elite_login
  #Verify successful login
  if e.has_gamertag? home
    log.info "Signed in..." 
    #Grab stats for use in output message
    totals = e.get_zombie_stats m
  else
    log.error "Verify login information: Gamertag did not match!"
  end
ensure
  Zombie.connection.close
end
