require File.expand_path('../helper', __FILE__)

class BackupFileItemTest < Test::Unit::TestCase
  def test_semantic_path
    assert_equal __FILE__, Backup::FileItem.semantic_path(__FILE__)
    assert_equal File.dirname(__FILE__) + '/',
                 Backup::FileItem.semantic_path(File.dirname(__FILE__))
  end

  def test_file_stat
    file = Backup::FileItem.stat(__FILE__, Backup::Timestamp.create)
    key = file.keys.first

    assert_not_nil file[key][:uid]
    assert_not_nil file[key][:gid]
    assert_not_nil file[key][:mode]
    assert_not_nil file[key][:checksum]
    assert_not_nil file[key][:timestamp]
  end

  def test_directory_stat
    file = Backup::FileItem.stat(File.dirname(__FILE__), Backup::Timestamp.create)
    key = file.keys.first

    assert_not_nil file[key][:uid]
    assert_not_nil file[key][:gid]
    assert_not_nil file[key][:mode]
    assert_nil file[key][:checksum]
    assert_not_nil file[key][:timestamp]
  end
end