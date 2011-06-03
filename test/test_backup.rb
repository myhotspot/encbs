require File.expand_path("../helper.rb", __FILE__)

class TestBackup < Test::Unit::TestCase
  def setup
    @backups_path = File.expand_path("../fixtures/backups", __FILE__)

    FileUtils.rm_r @backups_path, :force => true
    FileUtils.mkdir_p @backups_path

    @hostname = Socket.gethostname

    @backup = Backup::Instance.new(
      @backups_path,
      false
    )
  end

  def test_backup_attributes
    assert_equal(
      @backup.root_path,
      "#{@backups_path}/#{@hostname}"
    )
    assert_equal @backup.hostname, @hostname
    assert_equal @backup.file_item.class, Backup::FileItem::Local
    assert_not_nil @backup.timestamp
  end

  def test_create
    local_path = File.expand_path('../fixtures/etc', __FILE__)
    local_path_hash = Digest::MD5.hexdigest local_path

    timestamp = @backup.create! local_path, false, false
    back_path = "#{@backups_path}/#{@hostname}"

    assert File.exists?("#{back_path}")
    assert File.exists?("#{back_path}/meta")
    assert File.exists?("#{back_path}/meta/#{local_path_hash}")
    assert File.exists?("#{back_path}/meta/#{local_path_hash}/#{timestamp}.yml")
    assert File.exists?("#{back_path}/meta/jars")
    assert File.exists?("#{back_path}/meta/jars/#{local_path_hash}")
    assert File.exists?("#{back_path}/#{local_path_hash}")

    assert_equal "#{local_path}/", open("#{back_path}/meta/jars/#{local_path_hash}").read.chomp
    meta_index = YAML::load open("#{back_path}/meta/#{local_path_hash}/#{timestamp}.yml").read
    assert meta_index.has_key? local_path

    root_file = File.expand_path '../fixtures/etc/root/file', __FILE__
    assert_equal open(root_file).read, open(
      "#{back_path}/#{local_path_hash}/#{timestamp}/#{Digest::MD5.hexdigest root_file}"
    ).read
  end

  #def test_show_jars
  #end

  #def test_jar_versions
  #end

  #def test_restore
  #end
end
