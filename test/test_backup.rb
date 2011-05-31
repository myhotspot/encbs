require File.expand_path("../helper.rb", __FILE__)

class TestBackup < Test::Unit::TestCase
  def setup
    @backups_path = File.expand_path("../fixtures/backups", __FILE__)

    FileUtils.rm_r @backups_path, :force => true
    FileUtils.mkdir_p @backups_path

    @backup = Backup::Instance.new(
      @backups_path,
      false
    )
  end
  
  def test_backup_attributes
    hostname = Socket.gethostname
    
    assert_equal(
      @backup.root_path,
      "#{@backups_path}/#{hostname}"
    )
    assert_equal @backup.hostname, hostname
    assert_equal @backup.file_item.class, Backup::FileItem::Local
    assert_not_nil @backup.timestamp
  end
  
  def test_create
    local_path = File.expand_path('../fixtures/etc', __FILE__)
    local_path_hash = Digest::MD5.hexdigest local_path

    @backup.create! local_path, false, false
    
    assert File.exists?("#{@backups_path}/#{Socket.gethostname}")
    assert File.exists?("#{@backups_path}/#{Socket.gethostname}/meta")
    assert File.exists?("#{@backups_path}/#{Socket.gethostname}/meta/jars")
    assert File.exists?("#{@backups_path}/#{Socket.gethostname}/meta/jars/#{local_path_hash}")
    assert File.exists?("#{@backups_path}/#{Socket.gethostname}/#{local_path_hash}")
  end
  
  def test_show_jars
  end
  
  def test_jar_versions
  end
  
  def test_restore
  end
end