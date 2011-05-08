module Backup
  class Timestamp
    def self.parse_timestamp(version, last = false)
      version = version.gsub(".", "").gsub(" ", "").gsub(":", "")

      puts_fail "Invalid date format: #{version}" unless version.match /[0-9]{6,}/

      year, month, day, hour, min, sec =
        version.split(/([0-9]{2})/).map do |date|
          date.to_i unless date.empty?
        end.compact

      if last
        hour = 23 if hour.nil?
        min = 59 if min.nil?
        sec = 59 if sec.nil?
      end

      time = Time.new(year + 2000, month, day, hour, min, sec, 0)
    end

    def self.last_from(list, end_date, start_date = nil)
      list.sort.reverse.find do |version|
        version = Backup::Timestamp.parse_timestamp version

        unless start_date.nil?
          version >= start_date and version <= end_date
        else
          version <= end_date
        end
      end
    end

    def self.create(time = nil)
      time = time.nil? ? Time.now : time

      time.utc.strftime "%y%m%d%H%M%S"
    end

    def self.to_str(version)
      to_s parse_timestamp(version)
    end

    def self.to_s(time)
      time.strftime "%y.%m.%d %H:%M:%S" if time.is_a? Time
    end
  end
end
