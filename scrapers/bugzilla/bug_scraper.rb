class BugScraper < Bugzilla

  def initialize
    super
  end

  def scrape_all from=0, to=-1
    bug_ids = @mysql_connection.query("SELECT bug_id FROM bugs").map{ |b| b['bug_id'] }

    p "Parsing #{bug_ids.count} bugs..."

    @progressbar = ProgressBar.create(
      format:         "%a %b\u{15E7}%i %p%% %t",
      progress_mark:  " ",
      remainder_mark: "\u{FF65}",
      starting_at:    1,
      total:          bug_ids[from.to_i..to.to_i].count + 1
    )

    bug_ids.each do |bug_id|
      bug = scrape_one(bug_id)
      write_dump "bugs/#{bug_id}", bug
      @progressbar.increment
    end

    @progressbar.finish
  end

  private

  def scrape_one bug_id
    mysql_data = @mysql_connection.query("SELECT * FROM bugs WHERE bug_id = #{bug_id}").first

    cc_ids = @mysql_connection.query("SELECT who FROM cc WHERE bug_id = #{bug_id}").map{ |cc| cc['who'] }
    if cc_ids.empty?
      cc = ''
    else
      cc = @mysql_connection.query("SELECT * FROM profiles WHERE userid IN (#{cc_ids.join(',')})")
      cc = cc.map{|u| u['realname']}
    end

    keyword_ids = @mysql_connection.query("SELECT * FROM keywords WHERE bug_id = #{bug_id}").map{ |k| k['keywordid'] }
    if keyword_ids.empty?
      keywords = ''
    else
      keywords = @mysql_connection.query("SELECT * FROM keyworddefs WHERE id IN (#{keyword_ids.join(',')})")
      keywords = keywords.map{ |k| k['name'] }
    end

    product   = @mysql_connection.query("SELECT name FROM products   WHERE id = #{mysql_data['product_id']}").first['name']
    component = @mysql_connection.query("SELECT name FROM components WHERE id = #{mysql_data['component_id']}").first['name']

    data = {
      id:                bug_id,
      name:              mysql_data['short_desc'],
      status:            mysql_data['bug_status'],
      resolution:        mysql_data['resolution'],
      version:           mysql_data['version'],
      hardware:          mysql_data['rep_platform'],
      operation_system:  mysql_data['op_sys'],
      priority:          mysql_data['priority'],
      severity:          mysql_data['bug_severity'].split(' ')[0],
      created_at:        mysql_data['creation_ts'],
      created_by:        get_username_by_id(mysql_data['reporter']),
      updated_at:        mysql_data['lastdiffed'],
      assigned_to:       get_username_by_id(mysql_data['assigned_to']),
      cc:                cc,
      url:               mysql_data['bug_file_loc'],
      keywords:          keywords,
      product:           product,
      component:         component
    }

    data.merge! scrape_comments(bug_id)
    data.merge! scrape_attachments(bug_id)
    data
  end

  def scrape_comments bug_id

    comments = @mysql_connection.query("SELECT * FROM longdescs WHERE bug_id = #{bug_id} ORDER BY bug_when DESC")

    if comments.count == 0
      comments = []
    else
      comments = comments.map do |c|
        full_name = @mysql_connection.query("SELECT * FROM profiles WHERE userid = #{c['who']}").first['realname']
        {user: full_name, note: c['thetext'], date: c['bug_when'] }
      end
    end

    {comments: comments}
  end

  def scrape_attachments bug_id
    attachments = @mysql_connection.query("select a.attach_id, a.filename, a.creation_ts, a.description, a.submitter_id, ad.thedata from attachments a INNER JOIN attach_data ad ON ad.id = a.attach_id where a.bug_id = #{bug_id}")

    data = []

    if attachments.count != 0
      attachment_folder = "data/attachments/#{bug_id}"
      Dir.mkdir(attachment_folder) unless File.exists?(attachment_folder)

      attachments.each do |attachment|
        author = get_username_by_id attachment['submitter_id']
        file   = File.join(attachment_folder, attachment['filename'])

        File.open(file, 'wb'){ |f| f.puts attachment['thedata'] }

        data << {
          file:        file,
          author:      author,
          description: attachment['description'],
          created_at:  attachment['creation_ts']
        }
      end
    end

    {attachments: data}
  end

  protected

  def get_username_by_id id
    @mysql_connection.query("SELECT * FROM profiles WHERE userid = #{id}").first['realname']
  end

end