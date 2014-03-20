require 'cinch'
require 'csv'

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "Hearthy"  
    c.server          = "irc.sandcat.nl"
    c.channels        = ["#hs"]
  end

  helpers do
    def reply_card(m, card, colors)
        # first line: name - type - (race) - class
        reply = Format("%s - #{card["Type"]}" % [Format(colors[card["Rarity"]], card["Name"])])
        reply += " (#{card["Race"]})" if card["Race"] != nil
        reply = Format(:bold, reply)
        if card["Class"] != nil and card["Class"] != "All" then 
          reply += Format(colors[card["Class"]], " - #{card["Class"]}")
        end
        m.reply reply
        
        # mana and if available, attack and health
        reply = ""
        reply += "M:" + "#{card["Mana"]} " if card["Mana"] != nil
        reply += "| A:" + "#{card["Attack"]} " if card["Attack"] != nil
        reply += "H:" + "#{card["Health"]}" if card["Health"] != nil
 		m.reply Format(:bold, reply)

        # description if applicable
        m.reply Format(:lime, "#{card["Description"]}") if card["Description"] != nil
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
      cards = CSV.read('cards.csv', :headers => true, :converters=>:numeric, :encoding =>"UTF-8")
    
      # search for all instances of query in the Name column
      found_cards = Array.new
      cards.each { |card|
        # check if we are searching on description
        if query.downcase.split(":").first == 'desc'
          if (card["Description"] != nil && card["Description"].downcase[query.downcase.split(":").last] != nil) then
            found_cards.push(card)
          end
        # check if we are searching on race
        elsif query.downcase.split(":").first == 'race'
          if (card["Race"] != nil && card["Race"].downcase[query.downcase.split(":").last] != nil) then
            found_cards.push(card)
          end
        # search on the total string
        else
          if (card["Name"].downcase[query.downcase] != nil) then 
            found_cards.push(card)
          end
        end
      }      
      found_cards = found_cards.sort_by {|i| [i["Class"], i["Name"]]}

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
          if card["Class"] != current_class
            current_class = card["Class"] 
            card_string += "\n" + Format(colors[card["Class"]], card["Class"] + ': ')
          end 
          card_string += Format(colors[card["Rarity"]], "["+card["Name"]+"]") 
          card_array.push(card_string)
        end

        card_array_string = card_array.join(" ")

        card = found_cards.select{ |c| c["Name"].downcase == query.downcase }[0]
		# if there is an exact match, display the card, else, display all the options
        if (!card.nil?) then
          reply_card(m, card, colors)
        else
          # and print them
          if (found_cards.length <= 50) then
            m.reply "\001ACTION " + Format(:green, "heeft #{found_cards.length} kaarten gevonden: " + Format(:bold, "#{card_array_string}"))
          else 
            m.reply "\001ACTION " + Format(:green, "heeft #{found_cards.length} kaarten gevonden. Omdat het er meer dan 50 zijn laat ik ze niet zien.")
          end
        end
      end
    end
  end

  on :message, /\[([^\]]+)\]/ do |m, query|
    #m.reply "\001ACTION zoekt naar [#{query}]\001"
    hs(m, query)
  end

  trap "SIGINT" do
    bot.quit
  end
end

bot.start
