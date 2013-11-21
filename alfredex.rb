require 'yaml'
require File.join(File.dirname(__FILE__), 'alfred_feedback.rb')

class Alfredex
  FILE_DATA = YAML.load_file(File.join(File.dirname(__FILE__), 'pokemon.yml'))

  def self.search(string)
    matches = nil

    if string =~ /[\/,\,]/ # contains separators, look up multiple
      mons = string.split(/[\/,\,]/).map{|n| n.strip.downcase }
      dashed_mons = mons.select{|m| m =~ /\-/}

      matches = FILE_DATA.select do |name, data|
        if mons.include? name.downcase
          true
        elsif dashed_mons.length > 0 # contains dash and doesn't match, split
          dashed_mons.any?{|m| m.split('-')[0] == name.downcase }
        end
      end

      # maximum 10 lookups, don't flood the user with tabs
      matches = matches.to_a[0..9]

      feedback = Feedback.new
      feedback.add_item({
        :title => "Find Multiple Pokemon",
        :subtitle => matches.map{|m| m[0]}.join(', '),
        :arg => matches.map{|m| m[1]['url_name'] }.join(","),
        :uid => matches.map{|m| m[1]['number'] }.join(','),
        :icon => {:type => "filetype", :name => "icon.png"}
      })

      puts feedback.to_xml
    else # single pokemon
      if string =~ /^[0-9]+$/ # numeric string, check pokemon number
        matches = FILE_DATA.select do |name, data|
          data['number'].to_i == string.to_i
        end
      else # check for name
        matches = FILE_DATA.select do |name, data|
          name.downcase.include? string.downcase
        end
        matches = matches.sort_by do |k,v|
          k.downcase[0..string.length-1] == string.downcase ? 0 : 1
        end
      end

      feedback = Feedback.new
      matches.each do |name, data|
        feedback.add_item({
          :title => "##{data['number'].to_i} #{name}",
          :subtitle => data['description'],
          :arg => data['url_name'],
          :uid => data['number'],
          :icon => {:type => "filetype", :name => "pokemon_sprites/#{data['number']}.png"}
        })
      end

      puts feedback.to_xml
    end
  end
end

Alfredex.search ARGV.join.strip
