require 'base64'
require 'json'
require 'open-uri'
require 'zip'
require_relative 'lib/TemporaryExposureKeyExport_pb'

# Clean-up
Dir.glob('data/*/*').each do |file_name|
  File.delete(file_name)
end

# Download TEK files.
list = JSON.parse(File.read('data/list.json'))
list.each do |file|
  url = file['url']

  # Download all ZIP files.
  open(url) do |zip|
    File.open(File.join('data', 'zip', url.split('/').last), 'w') do |file|
      file.write(zip.read)
    end
  end

  # Extact all ZIP files.
  Dir.glob('data/zip/*.zip').each do |file_name|
    Zip::File.open(file_name) do |zip|
      zip.each do |entry|
        if entry.name == 'export.bin'
          file_num = file_name.split('.').first.split('/').last
          zip.extract(
            entry,
            File.join(
              'data/bin',
              [file_num, 'bin'].join('.')
            )
          ) { true }
        end
      end
    end
  end
end

# Decode TEK files
files = Dir.glob('data/bin/*.bin')
keys = files.collect do |file|
  teks = TemporaryExposureKeyExport.decode File.read(file)
  teks.keys.collect(&:key_data).collect { |b64| Base64.encode64 b64 }
end

puts keys, keys.size