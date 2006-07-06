module GDV
    def self.version
        "0.0.1"
    end

    def self.format_path
        File::join(File::dirname(__FILE__), "..", "format")
    end

    def self.log(msg)
        puts "#{msg}" if false
    end
end

require 'gdv/format.rb'