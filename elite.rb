require 'mechanize'
require 'logger'

class Elite
  attr_reader :email, :password, :gamertag, :log
  # Initialize object with credentials and formatted logger
  def initialize creds={}
    @email = creds["email"] || nil
    @password = creds["password"] || nil
    @gamertag = creds["gamertag"] || nil
    @log = Logger.new(File.expand_path(__FILE__+'/../elite_scan.log'))
    @log.datetime_format = "%F %T"
    @log.formatter = proc do |severity, datetime, progname, msg|
      "#{severity} [#{datetime}] -- #{msg}\n"
    end
  end

  # ATM, useful for testing attribute values
  def to_s
    "#{@email} #{@password} validates #{@gamertag}"
  end

  # Use attributes to return a new Mechanize agent and page
  # after successful login to elite.callofduty.com
  def elite_login
    agent = Mechanize.new
    page = agent.get('https://elite.callofduty.com/?redirectUrl=https%3A%2F%2Felite.callofduty.com%2Fplayer%2Fhome')
    link = page.link_with(class: "login_link")
    page = link.click
    login_form = page.form_with(id: "frmLogin")
    email_input = login_form.field_with(id: "j_username")
    email_input.value = @email.to_s
    password_input = login_form.field_with(id: "j_password")
    password_input.value = @password.to_s
    page = login_form.submit
    return agent, page
  end

  # Gathers a report of Zombie stats, given a Mechanize agent after
  # logging into elite.callofduty.com
  def get_zombie_stats agent
    zombies = agent.get('https://elite.callofduty.com/zombies')
    if has_gamertag? zombies
      @log.info "Getting Zombies stats..." 
      content = clean_html(zombies.body.to_s)
      values = content.scan(/Kills<\/p><pclass=\"value\">(.*)<\/p>/).first.first.scan(/\d+/)
      scan_time = Time.now.strftime("%F %T")
      values = values[0..7] << scan_time << @gamertag
      stats = {}
      Zombie.column_names.each_with_index do |c,i|
        stats[c] = values[i]
      end
      # values is structured as: kills, accuracy%, headshots%, revives, doors, perks, 
      # grenade kills, traveled miles, date, gamertag
      record = Zombie.new(stats)
      if record.save!
        @log.info "Stats updated!"
        record
      end
    else
      @log.error "Wrong Gamertag. Exiting!"
    end
  end

  # Verify state of login on elite.callofduty.com
  def has_gamertag? page
    return page.body.to_s.include?(@gamertag)
  end

  private

    # Strips whitespace from given string; intended for HTML
    def clean_html string
      return string.gsub(/[\n\t\r ]+/,'')
    end
end