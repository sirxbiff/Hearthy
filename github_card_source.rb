require_relative 'github_hash_card'
require 'json'

class GithubCardSource
  def cards
    gianthash = JSON.parse(open('all-cards.json').read)
    gianthash["cards"].select{ |c| c["set"] != "missions" }.map{ |c| GithubHashCard.new(c) }
  end
end
