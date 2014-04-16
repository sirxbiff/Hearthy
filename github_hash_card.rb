class GithubHashCard
  def initialize(hash)
    @data_hash = hash
  end

  def capitalize_validate_value(key)
    value = @data_hash[key.downcase]
    if ((value.nil?) || (value == "none") || (value == ""))
      nil
    else
      value.to_s.gsub(/<\/?b>/, "").capitalize
    end
  end

  # Catch-all methods for lazy developers
  def [] (key)
    capitalize_validate_value(key)
  end

  def method_missing(meth, *args, &block)
    if @data_hash.has_key?(meth.id2name)
      capitalize_validate_value(meth.id2name)
    else
      super
    end
  end

  def respond_to?(meth)
    if @data_hash.has_key?(meth.id2name)
      true
    else
      super
    end
  end

  def attack
    if (self.type == "Minion")
      if capitalize_validate_value("attack").nil?
        0
      else
        capitalize_validate_value("attack")
      end
    else
      capitalize_validate_value("attack")
    end
  end 

  def type
    capitalize_validate_value("category")
  end

  def name
    @data_hash["name"]
  end
  
  def rarity
    if (@data_hash["quality"] == "free")
      "Basic"
    else 
      capitalize_validate_value("quality")
    end
  end

  def collectible
    @data_hash["collectible"]
  end

  def class
    if (@data_hash["hero"] == "neutral")
      "All"
    else
      capitalize_validate_value("hero")
    end
  end
end
