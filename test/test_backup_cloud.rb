require File.expand_path('../helper', __FILE__)
require File.expand_path('../test_backup_local', __FILE__)

class TestCloudBackup < TestLocalBackup
  def setup
    @backups_path = "backups"
    @restore_path = File.expand_path("../fixtures/restore", __FILE__)
    @hostname = Socket.gethostname

    cloud_rc = YAML::load open(
      File.expand_path "../cloudrc.yml", __FILE__
    ).read

    @backup = Backup::Instance.new(
      @backups_path,
      true,
      :key => cloud_rc["key"],
      :secret => cloud_rc["secret"],
      :bucket => cloud_rc["bucket"]
    )
  end

  def teardown
    FileUtils.rm_r @restore_path, :force => true
    FileUtils.mkdir_p @restore_path

    File.open(File.expand_path('../fixtures/etc/root/file', __FILE__), 'w') do |f|
      f.puts "Root file\n"
    end

    @backup.file_item.delete_dir "backups"
  end

  def test_backup_attributes
    assert_equal(
      @backup.root_path,
      "#{@backups_path}/#{@hostname}"
    )
    assert_equal @backup.hostname, @hostname
    assert_equal @backup.file_item.class, Backup::FileItem::Cloud
    assert_not_nil @backup.timestamp
  end
end
