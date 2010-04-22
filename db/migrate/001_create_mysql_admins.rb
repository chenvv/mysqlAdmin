class CreateMysqlAdmins < ActiveRecord::Migration
  def self.up
    create_table :mysql_admins do |t|
    end
  end

  def self.down
    drop_table :mysql_admins
  end
end
