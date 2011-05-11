require File.expand_path("../helper.rb", __FILE__)

class TestBackup < Test::Unit::TestCase
	def setup
    @backup = Backup::Instance.new(
      File.expand_path("../fixtures/backups", __FILE__),
      false
    )
  end
  
  def test_backup_attributes
    hostname = Socket.gethostname
    file = File.expand_path("../fixtures/backups", __FILE__)
    
    assert_equal(
      @backup.root_path,
      "#{file}/#{hostname}"
    )
    assert_equal @backup.hostname, Socket.gethostname
    assert_equal @backup.file_item.class, Backup::FileItem::Local
    assert_not_nil @backup.timestamp
  end
  
  def test_create
  end
  
  def test_show_jars
  end
  
  def test_jar_versions
  end
  
  def test_restore
  end
end