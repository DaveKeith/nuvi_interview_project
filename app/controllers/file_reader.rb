require "set"
require "pry"
require "redis"
require "open-uri"
require 'rubygems'
require 'zip'

class FileReader
  def download_files(mydata, mac_path)
    # data = []
    # find_directories(mydata).each do |dir|
    #   from_path = mydata+dir
    #   to_path = mac_path+dir
    #   File.open(to_path, "wb") do |file|
    #     file.write open(from_path).read
    #   end
    # end
    from_path = mydata+find_directories(mydata)[0]
    to_path = mac_path+find_directories(mydata)[0]
    File.open(to_path, "wb") do |file|
      file.write open(from_path).read
    end
  end

  def find_directories(mydata)
    data = []
    download = open(mydata)
    download_array = download.to_a
    download_array.each do |element|
      if element.include?("147")
        segment = element[17...34]
        data << segment
      end
    end
    data
  end

  def get_all_files(mac_path)
    all_data = []
    Dir.chdir(mac_path)
    zip_files = Dir.glob("*.zip")
    zip_files.each do |directory|
      unzip_file(directory, mac_path)
    end
    xml_files = Dir.glob("*.xml")
    get_dir_files(xml_files).each do |article|
      all_data << article
    end
    unique_data = all_data.uniq
    unique_data
  end

  def unzip_file (file, destination)
    FileUtils.mkdir_p(destination)
    Zip::File.open(file) do |zip_file|
      zip_file.each do |f|
        fpath = File.join(destination, f.name)
        zip_file.extract(f, fpath) unless File.exist?(fpath)
      end
    end
  end

  def get_dir_files(dir_files)
    all_data = []
    dir_files.each do |xml_file|
      all_data << get_file(xml_file)
    end
    all_data
  end

  def get_file(myfile)
    lines = []
    file = File.open(myfile, "r")
    while(line = file.gets)
      lines << line
    end
    file.close
    lines
  end

  def redis_data(mac_path)
    r = Redis.new
    count = 0
    get_all_files(mac_path).each do |xml_file|
      r.rpush(xml_file, count)
      count += 1
    end
    r
  end
end

fr = FileReader.new
puts "Enter your file path:"
path = gets.chomp

fr.download_files("http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/", path)
NEWS_XML = fr.redis_data(path)
