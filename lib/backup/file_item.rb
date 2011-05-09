require 'backup/file_item/local'
require 'backup/file_item/cloud'

module Backup
  module FileItem
    def self.for(type, *args)
      case type
        when :cloud
          Backup::FileItem::Cloud.new *args
        when :local
          Backup::FileItem::Local.new

        else
          puts_fail "Unknown '#{type}' type for FileItem"
      end
    end
  end
end
