require 'active_record'

ActiveRecord::Base.configurations['zombies'] = {
  adapter:    'postgresql',
  database:   'elite',
  user:       'brad',
  password:   'sourLemon$'
}

class Zombie < ActiveRecord::Base
  establish_connection "zombies"
  self.table_name = 'stats'
end