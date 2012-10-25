module PasswordGenerator
  @@words = []

  def load_words
    return @@words unless @@words.empty?

    data_file = File.join(File.dirname(__FILE__), '../..', 'data', 'words.csv')
    File.open(data_file, 'r').each_line do |word|
      @@words << word.chomp
    end

    @@words
  end

  def generate(word_count=3)
    words = load_words

    chosen_words = (1..word_count).reduce([]) do |chosen, _|
      loop do
        chosen_i = rand(0...words.count)
        unless chosen.include? words[chosen_i]
          chosen << words[chosen_i]
          break;
        end
      end
      chosen
    end
    chosen_words.join('')
  end

  module_function :generate
  module_function :load_words
end