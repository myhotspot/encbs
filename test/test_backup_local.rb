require File.expand_path('../helper', __FILE__)

class TestLocalBackup < Test::Unit::TestCase
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

  def create_backup! increment = false, purge = false
    @local_path = File.expand_path('../fixtures/etc', __FILE__)
    @local_path_hash = Digest::MD5.hexdigest @local_path

    @timestamp = @backup.create! @local_path, increment, purge
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

    assert @backup.file_item.exists?("#{@back_path}/meta/#{@local_path_hash}/#{@timestamp}.yml")
    assert @backup.file_item.exists?("#{@back_path}/meta/jars/#{@local_path_hash}")
    assert @backup.file_item.exists?("#{@back_path}/#{@local_path_hash}")

    assert_equal "#{@local_path}/", @backup.file_item.read_file(
      "#{@back_path}/meta/jars/#{@local_path_hash}"
    ).chomp

    meta_index = YAML::load @backup.file_item.read_file(
      "#{@back_path}/meta/#{@local_path_hash}/#{@timestamp}.yml"
    )

    assert meta_index.has_key? @local_path

    root_file = File.expand_path '../fixtures/etc/root/file', __FILE__
    assert_equal open(root_file).read, @backup.file_item.read_file(
      "#{@back_path}/#{@local_path_hash}/#{@timestamp}/#{Digest::MD5.hexdigest root_file}"
    )
  end

  def test_create_with_compress
    @backup.compression = "gzip"
    create_backup!

    meta_index = YAML::load @backup.file_item.read_file(
      "#{@back_path}/meta/#{@local_path_hash}/#{@timestamp}.yml"
    )

    assert meta_index.has_key? :compression
    assert_equal meta_index[:compression], 'GZIP'

    root_file = File.expand_path '../fixtures/etc/root/file', __FILE__
    assert_not_equal open(root_file).read, @backup.file_item.read_file(
      "#{@back_path}/#{@local_path_hash}/#{@timestamp}/#{Digest::MD5.hexdigest root_file}"
    )
  end

  def test_create_with_purge_previous
    create_backup!
    previous_timestamp = @timestamp.dup

    sleep 1
    create_backup! false, true

    versions = @backup.jar_versions @local_path

    assert_equal versions.length, 1
    assert_equal versions.first, @timestamp
    assert_not_equal @timestamp, previous_timestamp
  end

  def test_create_with_crypt
    @backup.rsa_key(
      File.expand_path('../fixtures/rsa_key.public', __FILE__),
      2048
    )
    private_key = Crypto::Key.from_file(
      File.expand_path('../fixtures/rsa_key.private', __FILE__),
      2048
    )

    create_backup!

    root_file = File.expand_path '../fixtures/etc/root/file', __FILE__
    root_file_content = open(root_file).read

    root_file_crypt_content = @backup.file_item.read_file(
      "#{@back_path}/#{@local_path_hash}/#{@timestamp}/#{Digest::MD5.hexdigest root_file}"
    )

    assert_not_equal root_file_content, root_file_crypt_content
    assert_equal root_file_content, private_key.decrypt_from_stream(
      root_file_crypt_content.chomp
    )
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

  def test_restore_with_decrypt
    @backup.rsa_key(
      File.expand_path('../fixtures/rsa_key.public', __FILE__),
      2048
    )
    create_backup!

    restore_path = File.expand_path '../fixtures/restore', __FILE__
    @backup.rsa_key(
      File.expand_path('../fixtures/rsa_key.private', __FILE__),
      2048
    )
    @backup.restore_jar_to @local_path_hash, @timestamp, restore_path

    root_file_content = open(
      File.expand_path '../fixtures/etc/root/file', __FILE__
    ).read
    root_file_decrypt_content = open(
      "#{@restore_path}/#{@local_path}/root/file"
    ).read

    assert_equal root_file_content, root_file_decrypt_content
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
    assert_equal root_file_content, @backup.file_item.read_file(
      "#{@back_path}/#{@local_path_hash}/#{@timestamp}/#{Digest::MD5.hexdigest root_file}"
    )
  end
end
