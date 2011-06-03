require File.expand_path('../helper', __FILE__)

class BackupTimestampTest < Test::Unit::TestCase
  def test_parse_timestamp
    assert_equal Backup::Timestamp.parse_timestamp("110102201130"),
                 Time.utc(2011, 01, 02, 20, 11, 30, 0)

    assert_equal Backup::Timestamp.parse_timestamp("11.01.02. 20:11:30"),
                 Time.utc(2011, 01, 02, 20, 11, 30, 0)

    assert_equal Backup::Timestamp.parse_timestamp("1101022011"),
                 Time.utc(2011, 01, 02, 20, 11, 0, 0)
    assert_equal Backup::Timestamp.parse_timestamp("11010220"),
                 Time.utc(2011, 01, 02, 20, 0, 0, 0)
    assert_equal Backup::Timestamp.parse_timestamp("110102"),
                 Time.utc(2011, 01, 02, 0, 0, 0, 0)

    assert_equal Backup::Timestamp.parse_timestamp("1101022011", true),
                 Time.utc(2011, 01, 02, 20, 11, 59, 0)
    assert_equal Backup::Timestamp.parse_timestamp("11010220", true),
                 Time.utc(2011, 01, 02, 20, 59, 59, 0)
    assert_equal Backup::Timestamp.parse_timestamp("110102", true),
                 Time.utc(2011, 01, 02, 23, 59, 59, 0)

    assert_not_equal Backup::Timestamp.parse_timestamp("110102201130"),
                     Time.utc(2011, 01, 02, 20, 11, 31, 0)

    assert_raise(RuntimeError) { Backup::Timestamp.parse_timestamp("11d10.,130") }
  end

  def test_last_from
    timestamps = ["110130090812", "110130103412", "110106121234"]

    assert_equal("110130103412",
                 Backup::Timestamp.last_from(timestamps,
                                Backup::Timestamp.parse_timestamp("110130", true)))
    assert_equal("110130090812",
                 Backup::Timestamp.last_from(timestamps,
                                Backup::Timestamp.parse_timestamp("11013009", true)))
    assert_equal("110106121234",
                 Backup::Timestamp.last_from(timestamps,
                                Backup::Timestamp.parse_timestamp("110106", true)))

    assert_equal("110130103412",
                 Backup::Timestamp.last_from(timestamps,
                                Backup::Timestamp.parse_timestamp("110130", true),
                                Backup::Timestamp.parse_timestamp("110130")))
    assert_equal("110106121234",
                 Backup::Timestamp.last_from(timestamps,
                                Backup::Timestamp.parse_timestamp("110110", true),
                                Backup::Timestamp.parse_timestamp("110101")))
    assert_equal("110130090812",
                 Backup::Timestamp.last_from(timestamps,
                                Backup::Timestamp.parse_timestamp("1101300908", true),
                                Backup::Timestamp.parse_timestamp("110130090811")))

  end

  def test_create_timestamp
    time = Time.utc(2011, 01, 02, 23, 59, 59, 0)

    assert_equal(Backup::Timestamp.create.length, 12)
    assert_equal(Backup::Timestamp.create(time), "110102235959")
  end

  def test_formatted_timestamp
    time = Time.utc(2011, 01, 02, 23, 59, 30, 0)

    assert_equal Backup::Timestamp.to_s(time), "11.01.02 23:59:30"
    assert_equal Backup::Timestamp.to_s(51), nil
    assert_equal Backup::Timestamp.to_str("110102235930"), "11.01.02 23:59:30"
  end
end
