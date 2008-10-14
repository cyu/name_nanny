# The Name Nanny makes sure that users behave themselves when on the system.
module NameNanny
  BAD_WORDS_LOCATION = File.dirname(__FILE__) + '/bad_words.txt' 

  def self.bad_words(*words)
    all = [ get_words(BAD_WORDS_LOCATION) ]
    words.inject(all) do |arr, v|
      arr << get_words("#{RAILS_ROOT}/config/#{v.to_s}_words.txt") if v; arr
    end
  end 

  def self.get_words(loc)
    @@words_cache ||= {}
    @@words_cache[loc] || (@@words_cache[loc] = IO.readlines(loc).collect(&:chop!))
  end
  
  # Use a non-descript error to prevent the users from trying to hack around the filter.
  # Hopefully, they will just give up and choose something nicer.
  def validates_wholesomeness_of(*attr_names)
    configuration = { :message => "is already taken" }
    configuration.merge!(attr_names.pop) if attr_names.last.is_a?(Hash)
    
    validates_each(attr_names) do |record, attr_names|
      unless !configuration[:if].nil? and not configuration[:if].call(record)
        words = NameNanny.bad_words(*configuration[:words])
        record.errors.add( attr_names, configuration[:message] ) unless wholesome?(record.send(attr_names), words)
      end
    end
  end

  def bleep_text(str,opts={})
    sub_text(str,"bleeep",opts)
  end

  def smurf_text(str,opts={})
    sub_text(str,"smurf",opts)
  end

  def strip_text(str,opts={})
    sub_text(str,"",opts)
  end

  def wholesome?(str, words=NameNanny.bad_words)
    bad_name = false
    str.split(" ").each do |name|
      name = $1 if name.match(/^(.*)[\?\.\!]$/) # strip punctuation
      bad_name = true if words.any? { |v| v.include?(name.downcase) }
    end
    !bad_name
  end

  protected
  def sub_text(str,replacement = "bleeep", opts={})
    bad_words = NameNanny.bad_words(*opts[:words])
    
    # Replace commas with an unlikely character combination
    str = str.gsub(',', ' ^&^ ')
    baddies = str.split(" ").map { | word | word.rstrip if bad_words.include?(word.rstrip.downcase) }.compact
    baddies.each { |word| str.gsub!(word, replacement) }
    
    # Return commas to their correct position within the string
    str = str.gsub(' ^&^ ', ',')
    str
  end
  
end
