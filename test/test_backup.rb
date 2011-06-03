require File.expand_path("../helper.rb", __FILE__)

class TestBackup < Test::Unit::TestCase
  def setup
    @backups_path = File.expand_path("../fixtures/backups", __FILE__)
    @restore_path = File.expand_path("../fixtures/restore", __FILE__)

    @hostname = Socket.gethostname

    @backup = Backup::Instance.new(
      @backups_path,
      false
    )
  end

  def teardown
    FileUtils.rm_r @backups_path, :force => true
    FileUtils.rm_r @restore_path, :force => true

    FileUtils.mkdir_p @backups_path
    FileUtils.mkdir_p @restore_path

    File.open(File.expand_path('../fixtures/etc/root/file', __FILE__), 'w') do |f|
      f.puts "Root file\n"
    end
  end

  def create_backup! increment = false
    @local_path = File.expand_path('../fixtures/etc', __FILE__)
    @local_path_hash = Digest::MD5.hexdigest @local_path

    @timestamp = @backup.create! @local_path, increment, false
    @back_path = "#{@backups_path}/#{@hostname}"
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
    create_backup!

    assert File.exists?("#{@back_path}")
    assert File.exists?("#{@back_path}/meta")
    assert File.exists?("#{@back_path}/meta/#{@local_path_hash}")
    assert File.exists?("#{@back_path}/meta/#{@local_path_hash}/#{@timestamp}.yml")
    assert File.exists?("#{@back_path}/meta/jars")
    assert File.exists?("#{@back_path}/meta/jars/#{@local_path_hash}")
    assert File.exists?("#{@back_path}/#{@local_path_hash}")

    assert_equal "#{@local_path}/", open(
      "#{@back_path}/meta/jars/#{@local_path_hash}"
    ).read.chomp

    meta_index = YAML::load open(
      "#{@back_path}/meta/#{@local_path_hash}/#{@timestamp}.yml"
    ).read

    assert meta_index.has_key? @local_path

    root_file = File.expand_path '../fixtures/etc/root/file', __FILE__
    assert_equal open(root_file).read, open(
      "#{@back_path}/#{@local_path_hash}/#{@timestamp}/#{Digest::MD5.hexdigest root_file}"
    ).read
  end

  def test_show_jars
    create_backup!

    jars = @backup.jars

    assert jars.has_key? "#{@local_path}/"
    assert_equal jars["#{@local_path}/"], Digest::MD5.hexdigest(@local_path)
  end

  def test_jar_versions
    create_backup!

    jar_timestamp = @backup.jar_versions @local_path

    assert_equal @timestamp, jar_timestamp.first
  end

  def test_restore
    create_backup!
    restore_path = File.expand_path '../fixtures/restore', __FILE__

    @backup.restore_jar_to @local_path_hash, @timestamp, restore_path

    assert "#{@restore_path}/#{@local_path}"
    assert "#{@restore_path}/#{@local_path}/etc/root/file"

    root_file_content = open(
      File.expand_path '../fixtures/etc/root/file', __FILE__
    ).read
    assert_equal root_file_content, open(
      "#{@restore_path}/#{@local_path}/root/file"
    ).read
  end

  def test_increment_backup
    create_backup!

    File.open(File.expand_path('../fixtures/etc/root/file', __FILE__), 'w') do |f|
      f.puts "Changed file\n"
    end

    sleep 1
    create_backup! true

    root_file = File.expand_path '../fixtures/etc/root/file', __FILE__
    root_file_content = open(root_file).read

    assert_equal root_file_content, "Changed file\n"
    assert_equal root_file_content, open(
      "#{@back_path}/#{@local_path_hash}/#{@timestamp}/#{Digest::MD5.hexdigest root_file}"
    ).read
  end
end
