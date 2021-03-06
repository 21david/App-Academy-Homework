require 'sqlite3'
require 'singleton'

class PlayDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('plays.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Play
  attr_accessor :title, :year, :playwright_id

  def self.find_by_title(title)
    items_from_database = PlayDBConnection.instance.execute(<<-SQL, title)
      SELECT *
      FROM plays
      WHERE title = ?
    SQL
    items_from_database.map { |item| Play.new(item) }
  end

  # returns all plays written by playwright
  def self.find_by_playwright(name)
    items_from_database = PlayDBConnection.instance.execute(<<-SQL, name)
      SELECT *
      FROM plays
      WHERE playwright_id = 
        (SELECT id
        FROM playwrights
        WHERE name = ?) -- get playwright's id
    SQL
    items_from_database.map { |item| Play.new(item) }
  end

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM plays")
    data.map { |datum| Play.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @year = options['year']
    @playwright_id = options['playwright_id']
  end

  def create
    raise "#{self} already in database" if self.id
    PlayDBConnection.instance.execute(<<-SQL, self.title, self.year, self.playwright_id)
      INSERT INTO
        plays (title, year, playwright_id)
      VALUES
        (?, ?, ?)
    SQL
    self.id = PlayDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless self.id
    PlayDBConnection.instance.execute(<<-SQL, self.title, self.year, self.playwright_id, self.id)
      UPDATE
        plays
      SET
        title = ?, year = ?, playwright_id = ?
      WHERE
        id = ?
    SQL
  end
end


class Playwright
  attr_accessor :name, :birth_year

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM playwrights") # returns an array of hashes
    data.map { |datum| Playwright.new(datum) }
  end

  def self.find_by_name(name)
    item = PlayDBConnection.instance.execute(<<-SQL, name)
      SELECT *
      FROM playwrights
      WHERE name = ?
    SQL
    Playwright.new(item.first)
  end

  def initialize(hash)
    @id = hash['id']
    @name = hash['name']
    @birth_year = hash['birth_year']
  end

  # save the instance to the database
  def create
    raise "#{self} already in database" if @id
    PlayDBConnection.instance.execute(<<-SQL, @name, @birth_year)
      INSERT INTO playwrights (name, birth_year)
      VALUES (?, ?)
    SQL
    @id = PlayDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    PlayDBConnection.instance.execute(<<-SQL, @name, @birth_year, @id)
      UPDATE playwrights
      SET name = ?, birth_year = ?
      WHERE id = ?
    SQL
  end

  # get all plays written by this playwright
  def get_plays
    PlayDBConnection.instance.execute(<<-SQL, @id)
      SELECT *
      FROM plays
      WHERE playwright_id = ?
    SQL
  end

end