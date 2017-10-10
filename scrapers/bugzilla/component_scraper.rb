class ComponentScraper < Bugzilla

  def initialize
    super
  end

  def scrape_all

    p "Parsing components..."

    data = read_dump 'products'

    @progressbar = ProgressBar.create(
      format:         "%a %b\u{15E7}%i %p%% %t",
      progress_mark:  " ",
      remainder_mark: "\u{FF65}",
      starting_at:    1,
      total: 600
    )

    data[:products].each do |product|

      components = @mysql_connection.query("SELECT * FROM components WHERE product_id = #{product[:id]}")

      if components.count == 0
        components = []
      else
        components = components.map do |component|

          author_id = component['initialowner']
          author    = @mysql_connection.query("SELECT * FROM profiles WHERE userid = #{author_id}").first

          bugs = @mysql_connection.query("SELECT bug_id FROM bugs WHERE component_id = #{component['id']}")

          {
            id:          component['id'],
            author:      author['realname'],
            name:        component['name'],
            description: component['description'],
            bug_ids:     bugs.map{ |b| b['bug_id']  }
          }
        end
      end

      product[:components] = components
    end

    @progressbar.finish

    write_dump 'components', data
  end

end