module DumpManager

  def self.clear_dumps!
    FileUtils.remove_dir 'data'             if File.directory?('data')
    FileUtils.mkdir_p    'data'             if !File.directory?('data')
    FileUtils.mkdir_p    'data/attachments' if !File.directory?('data/attachments')
    FileUtils.mkdir_p    'data/bugs'        if !File.directory?('data/bugs')
  end

  def write_dump name, data
    File.open("data/#{name}.json", 'w') do |file|
      file.puts data.to_json
    end
  end

  def read_dump name
    dump_file = File.read "data/#{name}.json"
    json_data = JSON.parse dump_file
    data      = Hashie.symbolize_keys json_data

    data
  end

  def dump_exists? name
    File.exists? "data/#{name}.json"
  end

end