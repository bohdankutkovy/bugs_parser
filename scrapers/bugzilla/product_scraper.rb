class ProductScraper < Bugzilla

  def initialize
    super
  end

  def scrape_all

    p 'Parsing products...'

    @progressbar = ProgressBar.create(
      format:         "%a %b\u{15E7}%i %p%% %t",
      progress_mark:  " ",
      remainder_mark: "\u{FF65}",
      starting_at:    1,
      total: 30
    )

    products = @mysql_connection.query("SELECT * FROM products")
    data     = {products: []}

    products.each do |product|

      data[:products] << {
        id:          product['id'],
        name:        product['name'],
        description: product['description']
      }

      @progressbar.increment
    end

    @progressbar.finish

    write_dump 'products', data
  end

end