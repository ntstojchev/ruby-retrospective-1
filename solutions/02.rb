class Collection
  attr_reader :songs

  def initialize(songs_as_text, artists_tags)
    songs_as_strings = []
    coll = []
    @songs = []
    songs_as_lines = songs_as_text.lines("\n") { |s| songs_as_strings << s }
    songs_as_strings.each { |s| coll << s.split(".") }
    coll.each { |s| @songs << Song.new(s) }
  end

  def find(criteria)
    output = []
    if criteria != {}
      if criteria.has_key? :name
        criteria_name(criteria,output)
      end
      if criteria.has_key? :artist
        criteria_artist(criteria,output)
      end
      if criteria.has_key? :tags
        criteria_tags(criteria,output)
      end
      if criteria.has_key? :filter
        criteria_filter(criteria, output)
      end
    else
      return songs
    end
    return output
  end

  def criteria_name(criteria, output)
    songs.each do |s|
      if find_name(criteria[:name], s)
        output << s
      end
    end
  end

  def criteria_artist(criteria, output)
    songs.each do |s|
      if find_artist(criteria[:artist], s)
        output << s
      end
    end
  end

  def criteria_tags(criteria, output)
    songs.each do |s|
      if find_tags(criteria[:tags], s)
        output << s
      end
    end
  end

  def criteria_filter(criteria, output)
    songs.each do |s|
      if yield s then output << s end
    end
  end

  def find_tags(tags, s)
    if s.tags != [""] then return s.tags.flatten.include? tags end
    false
  end

  def find_name(name, s)
    return s.name.eql? name
  end

  def find_artist(artist, s)
    return s.artist.eql? artist
  end
end

class Song
  attr_accessor :name
  attr_accessor :artist
  attr_accessor :genre
  attr_accessor :subgenre
  attr_accessor :tags

  def initialize(song)
    @tags = []
    @name = song[0].strip
    @artist = song[1].strip
    @genre = if song[2] != nil
               song[2].partition(",")[0].strip
             end
    @subgenre = if song[2] != nil
                  @tags << song[2].partition(",")[2].strip.downcase
                  song[2].partition(",")[2].strip
                end
    if song[3] != nil
      song[3] = song[3].strip
      @tags << song[3].split(", ")
      @tags.flatten!
    end
  end

  def print
    p "Name: #{@name}"
    p "Artist: #{@artist}"
    p "Genre: #{@genre}"
    p "Subgenre: #{@subgenre}"
    p "Tags: #{@tags}"
  end
end