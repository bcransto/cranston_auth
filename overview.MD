# Cranston Auth API - Simplified Specification

## Project Overview

Rails 8 API-only authentication microservice for an educational platform. Provides JWT-based authentication and user management for downstream services (game service, store service, education management service). Includes a minimal embedded admin interface (vanilla ERB views) for user management.

## Core Requirements

### Rails Setup

* Rails 8.0 API-only application with embedded admin namespace (ERB views)
* Ruby 3.4.5
* MySQL database
* JWT-based authentication
* **UUID primary keys** (Rails `id: :uuid` default)

### User Model

Single table with all user data:

```ruby
create_table :users, id: :uuid do |t|
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
  t.uuid :external_id, null: false
  
  t.timestamps
  
  # Indexes
  t.index :email, unique: true
  t.index :lasid, unique: true, where: "lasid IS NOT NULL"
  t.index :role
  t.index :deleted_at
  t.index :external_id, unique: true
end
```

### User Model Features

* **Roles**: student (0), teacher (1), admin (2) - using Rails enum
* **LASID**: 4-digit string, required for students only, nil for teachers/admins
* **External ID**: UUID generated on creation for cross-service references
* **Soft Delete**: Uses deleted\_at field, excluded from authentication
* **Validations**:

  * Email: unique (case-insensitive), valid format
  * LASID: exactly 4 digits for students, nil for others
  * Password: minimum 6 characters
* **Scopes**:

  * `active` - where deleted\_at is nil
  * `deleted` - where deleted\_at is not nil

### API Endpoints

```
POST   /api/v1/auth/login           # User login (all roles)
GET    /api/v1/auth/validate        # Validate token (for other services)

GET    /api/v1/users                # List users (admin only)
POST   /api/v1/users                # Create user (admin only)
GET    /api/v1/users/:id            # Show user (self or admin)
PATCH  /api/v1/users/:id            # Update user (self or admin)
DELETE /api/v1/users/:id            # Soft delete user (admin only)
POST   /api/v1/users/:id/restore    # Restore user (admin only)
```

### Authentication System

* JWT tokens expire after 24 hours
* Single login endpoint for all user types
* Token payload: `{ user_id: id, email: email, role: role, external_id: external_id, exp: timestamp }`
* No refresh tokens (can be added later if needed)

### Key Gems

```ruby
# Gemfile additions
gem 'bcrypt'
gem 'jwt'
gem 'rack-cors'
```

### CORS Configuration

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3000', 'http://localhost:3001', 'http://localhost:3002'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization']
  end
end
```

## Implementation Classes

### User Model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  self.primary_key = :id

  has_secure_password
  
  # Generate external ID for cross-service references
  before_create :generate_external_id
  
  # Enums
  enum role: { student: 0, teacher: 1, admin: 2 }
  
  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: :password_required?
  validate :validate_lasid_by_role
  
  # Callbacks
  before_save :normalize_email
  
  # Instance methods
  def soft_delete
    update(deleted_at: Time.current)
  end
  
  def restore
    update(deleted_at: nil)
  end
  
  def deleted?
    deleted_at.present?
  end
  
  def track_successful_login!
    update(
      last_login_at: Time.current,
      login_count: (login_count || 0) + 1
    )
  end
  
  # Class methods
  def self.authenticate_user(email, password)
    user = active.find_by(email: email&.downcase&.strip)
    return nil unless user&.authenticate(password)
    
    user.track_successful_login!
    user
  end
  
  private
  
  def generate_external_id
    self.external_id ||= SecureRandom.uuid
  end
  
  def normalize_email
    self.email = email&.downcase&.strip
  end
  
  def password_required?
    new_record? || password.present?
  end
  
  def validate_lasid_by_role
    if student?
      errors.add(:lasid, "must be exactly 4 digits") unless lasid&.match?(/^\d{4}$/)
    elsif lasid.present?
      errors.add(:lasid, "must be nil for teachers and admins")
    end
  end
end
```

## Embedded Admin Interface

A minimal admin interface is embedded directly in the same Rails app under an `Admin` namespace. This interface uses **ERB views and Rails sessions** for authentication, separate from the JWT system.

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/login', to: 'authentication#login'
      get 'auth/validate', to: 'authentication#validate'
      
      # Users
      resources :users, except: [:new, :edit] do
        member do
          post 'restore'
        end
      end
    end
  end

  namespace :admin do
    resources :users do
      member do
        post 'restore'
      end
    end
    get '/', to: 'users#index'
  end
end
```

### Admin::UsersController

```ruby
# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < ApplicationController
    layout 'admin'
    
    def index
      @users = User.all
    end

    def show
      @user = User.find(params[:id])
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_user_path(@user), notice: 'User created successfully.'
      else
        render :new
      end
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: 'User updated successfully.'
      else
        render :edit
      end
    end

    def destroy
      @user = User.find(params[:id])
      @user.soft_delete
      redirect_to admin_users_path, notice: 'User deleted successfully.'
    end

    def restore
      @user = User.find(params[:id])
      @user.restore
      redirect_to admin_user_path(@user), notice: 'User restored successfully.'
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :role, :lasid, :first_name, :last_name, :nickname, :date_of_birth)
    end
  end
end
```

### Views

Located in `app/views/admin/users/`:

* `index.html.erb`: list users
* `show.html.erb`: show details
* `new.html.erb` and `edit.html.erb`: basic forms

### Layout

`app/views/layouts/admin.html.erb` – super vanilla HTML layout with a header and yield.

---

## Database Seeds

Updated to support UUIDs automatically via Rails migrations (no changes needed in seed format).

---

## Notes for Other Services

When other microservices need to validate tokens:

1. They can decode the JWT themselves (if they have the secret key)
2. OR call `/api/v1/auth/validate` endpoint
3. Use the `external_id` field (UUID) for cross-service references

---

## Next Steps

* Expand embedded admin as needed (currently MVP CRUD).
* Add authorization layer (Pundit) if more complex rules emerge.
