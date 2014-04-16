require 'cinch'
require 'csv'
require_relative 'github_card_source'

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "Hearthy"  
    c.server          = "irc.sandcat.nl"
    c.channels        = ["#hs"]
  end

  helpers do
    def reply_card(m, card, colors)
        # first line: name - type - (race) - class
        reply = Format("%s - #{card.type}" % [Format(colors[card.rarity], card.name)])
        reply += " (#{card.race})" if card.race != nil
        reply = Format(:bold, reply)
        if card.class != nil and card.class != "All" then 
          reply += Format(colors[card.class], " - #{card.class}")
        end
        if !card.collectible then
          reply += Format(:bold, " - Token")
        end
        m.reply reply
        
        # mana and if available, attack and health
        reply = ""
        reply += "M:" + "#{card.mana} " if card.mana != nil
        reply += "| A:" + "#{card.attack} " if card.attack != nil
        reply += "H:" + "#{card.health}" if card.health != nil
 		m.reply Format(:bold, reply)

        # description if applicable
        m.reply Format(:lime, "#{card.description}") if card.description != nil
    end

    def hs(m, query)
      #  http://rubydoc.info/gems/cinch/Cinch/Formatting     
      colors = Hash.new
      colors["Druid"] = :red
      colors["Mage"] = :aqua
      colors["Warlock"] = :purple
      colors["Shaman"] = :blue
      colors["Warrior"] = :orange
      colors["Priest"] = :white
      colors["Rogue"] = :yellow
      colors["Hunter"] = :lime
      colors["Paladin"] = :pink

      colors["Epic"] = :purple
      colors["Legendary"] = :red
      colors["Rare"] = :blue
      colors["Common"] = :white
      colors["Basic"] = :white

      # I should perhaps load the list once instead of every query XXX
      # cards obtained from http://hearthstonecardlist.com/
      # open the cards csv file for reading while maintaining column headers and converting numeric values
      #cards = CSV.read('cards.csv', :headers => true, :converters=>:numeric, :encoding =>"UTF-8")
      cards = GithubCardSource.new.cards
    
      # search for all instances of query in the Name column
      found_cards = Array.new
      cards.each { |card|
        # check if we are searching on description
        if query.downcase.split(":").first == 'desc'
          if (card.description != nil && card.description.downcase[query.downcase.split(":").last] != nil) then
            found_cards.push(card)
          end
        # check if we are searching on race
        elsif query.downcase.split(":").first == 'race'
          if (card.race != nil && card.race.downcase[query.downcase.split(":").last] != nil) then
            found_cards.push(card)
          end
        # search on the total string
        else
          if (card.name.downcase[query.downcase] != nil) then 
            found_cards.push(card)
          end
        end
      }      
      found_cards = found_cards.sort_by {|i| [i.class, i.name]}

      # act depending on the number of found cards
      case found_cards.length
      when 0
        m.reply "\001ACTION " + Format(:green, "heeft niets kunnen vinden voor [#{query}] :/")
      when 1 # one card found
        p found_cards[0]
        card = found_cards[0]

        reply_card(m, card, colors)
      
      else # when multiple cards look like the search query
        # stick all cardnames together
        card_array = Array.new
        current_class = ''
        # go through the cards, and display each class on a new row
        for card in found_cards
          card_string = '' 
          if card.class != current_class
            current_class = card.class 
            card_string += "\n" + Format(colors[card.class], card.class + ': ')
          end 
          card_string += Format(colors[card.rarity], "["+card.name+"]") 
          card_array.push(card_string)
        end

        card_array_string = card_array.join(" ")

        card = found_cards.select{ |c| c.name.downcase == query.downcase }[0]
        # always print all the options
        if (found_cards.length <= 50) then
          m.reply "\001ACTION " + Format(:green, "heeft #{found_cards.length} kaarten gevonden: " + Format(:bold, "#{card_array_string}"))
        else 
          m.reply "\001ACTION " + Format(:green, "heeft #{found_cards.length} kaarten gevonden. Omdat het er meer dan 50 zijn laat ik ze niet zien.")
        end
        
        # if there is an exact match, print it as well
        if (!card.nil?) then
          reply_card(m, card, colors)
        end
      end
    end
  end

  on :message, /\[([^\]]+)\]/ do |m, query|
    #m.reply "\001ACTION zoekt naar [#{query}]\001"
    hs(m, query)
  end

  on :message, /Well played.*Hearthy.?/ do |m, query|
    m.reply "You have bested me!"
    bot.quit
  end

  trap "SIGINT" do
    bot.quit
  end
end

bot.start
