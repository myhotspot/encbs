require File.expand_path("../helper.rb", __FILE__)

class TestBackup < Test::Unit::TestCase
	def setup
    @backup = Backup::Instance.new(
      File.expand_path("../fixtures/backups", __FILE__),
      false
    )
  end
  
  def test_backup_attributes
    
  end
end