class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: false do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      
      # Core fields
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :lasid, limit: 4
      t.integer :role, default: 0, null: false
      
      # Profile fields (all optional)
      t.string :first_name
      t.string :last_name
      t.string :nickname
      t.date :date_of_birth
      
      # Tracking fields
      t.datetime :last_login_at
      t.integer :login_count, default: 0
      t.datetime :deleted_at
      
      # External reference (for microservices)
      t.string :external_id, limit: 36, null: false
      
      t.timestamps
      
      # Indexes
      t.index :email, unique: true
      t.index :lasid, unique: true, where: "lasid IS NOT NULL"
      t.index :role
      t.index :deleted_at
      t.index :external_id, unique: true
    end
  end
end