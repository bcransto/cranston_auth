# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cranston Auth API - Rails 8.0 authentication microservice for an educational platform. Provides JWT-based authentication for downstream services (game service, store service, education management) with an embedded admin interface.

**Tech Stack:** Ruby 3.4.5, Rails 8.0, MySQL, JWT

## Development Commands

```bash
# Start server
rails server

# Database operations
rails db:create        # Create databases
rails db:migrate       # Run migrations
rails db:seed          # Load seed data
rails db:drop          # Drop databases (careful!)

# Development tools
rails console          # Interactive console
rails routes           # Show all routes
rails routes | grep admin  # Show admin routes
rails routes | grep api    # Show API routes

# Bundle management
bundle install         # Install gems
bundle update         # Update gems
```

## Architecture Overview

### Triple Authentication Systems

1. **JWT Authentication (API)**: For mobile apps and user clients
   - Token expires after 24 hours
   - Used by: `/api/v1/*` endpoints (except `/services/*`)
   - Token payload includes: user_id, email, role, external_id
   - Service: `app/services/jwt_service.rb`

2. **Session Authentication (Admin Web)**: For admin interface
   - Cookie-based sessions
   - Used by: `/admin/*` routes
   - Admin-only access
   - Controller: `app/controllers/admin/sessions_controller.rb`

3. **Service API Key Authentication**: For service-to-service communication
   - Static API keys via environment variables
   - Used by: `/api/v1/services/*` endpoints
   - Header: `X-Service-Api-Key`
   - Controller: `app/controllers/api/v1/services_controller.rb`

### User Model Architecture

- **UUID Primary Keys**: All tables use string-based UUIDs
- **Roles**: student (0), teacher (1), admin (2) via Rails enum
- **Soft Delete**: Users have `deleted_at` field, scoped with `active` and `deleted`
- **LASID**: 4-digit identifier required for students only
- **External ID**: UUID for cross-service references

### Authorization Hierarchy

Current permissions in `app/controllers/application_controller.rb`:
- `admin_only!`: Only admins can access
- `self_or_admin!`: Users can access own data, admins can access all
- `authenticate_service!`: Validates service API key for service-to-service calls

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - Login (returns JWT token)
- `GET /api/v1/auth/validate` - Validate token

### Users (requires JWT authentication)
- `GET /api/v1/users` - List all users (admin only)
- `POST /api/v1/users` - Create user (admin only)
- `GET /api/v1/users/:id` - Show user (self or admin)
- `PATCH /api/v1/users/:id` - Update user (self or admin)
- `DELETE /api/v1/users/:id` - Soft delete (admin only)
- `POST /api/v1/users/:id/restore` - Restore (admin only)

### Service Endpoints (requires service API key)
- `GET /api/v1/services/users/:external_id` - Get user by external_id
- `GET /api/v1/services/users?external_ids[]=id1&external_ids[]=id2` - Batch fetch users

### Admin Web Interface
- `/admin/login` - Admin login page
- `/admin/users` - User management
- `/admin/users/batch_new` - Batch import users via CSV

## Testing the API

### Test Credentials

```ruby
# Admin
email: admin@cranston.edu
password: password123

# Teachers
teacher1@cranston.edu / password123
teacher2@cranston.edu / password123

# Students (with LASID)
student1@cranston.edu / password123 / LASID: 1234
student2@cranston.edu / password123 / LASID: 5678
student3@cranston.edu / password123 / LASID: 9012
```

### API Testing Examples

```bash
# Login as admin
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@cranston.edu","password":"password123"}'

# Use token for authenticated requests
TOKEN="<token_from_login>"
curl -X GET http://localhost:3000/api/v1/users \
  -H "Authorization: Bearer $TOKEN"

# Service-to-service: Get user by external_id
curl -X GET http://localhost:3000/api/v1/services/users/02392ed0-0936-4bf6-966f-1271c56363eb \
  -H "X-Service-Api-Key: classroom_service_key_123"

# Service-to-service: Batch fetch users
curl -X GET "http://localhost:3000/api/v1/services/users?external_ids[]=id1&external_ids[]=id2" \
  -H "X-Service-Api-Key: classroom_service_key_123"
```

## Batch Import Format

CSV format for `/admin/users/batch_new`:
```csv
email,password,role,lasid,first_name,last_name,nickname,date_of_birth
student@example.edu,password123,student,1234,John,Doe,Johnny,2010-05-15
teacher@example.edu,password123,teacher,,Jane,Smith,,
```

## Current Authorization Rules

### API Access
- **Admins**: Full CRUD on all users
- **Teachers**: Can view/update own profile only
- **Students**: Can view/update own profile only

### Admin Interface Access
- **Only admin role** can access `/admin/*` routes
- Session-based authentication separate from JWT

## Key Files to Understand

- `app/models/user.rb` - User model with validations and soft delete
- `app/services/jwt_service.rb` - JWT token handling
- `app/controllers/application_controller.rb` - Base authorization methods
- `app/controllers/api/v1/authentication_controller.rb` - Login/validate endpoints
- `app/controllers/api/v1/users_controller.rb` - User CRUD with authorization
- `app/controllers/api/v1/services_controller.rb` - Service-to-service user lookups
- `app/controllers/admin/users_controller.rb` - Admin interface with batch import
- `config/application.rb` - Middleware configuration (modified from API-only)

## Service-to-Service Authentication

### Design Pattern
- Downstream services (classroom, game, store) maintain their own domain relationships
- They reference users via `external_id` as foreign key
- When user data is needed, services make direct API lookups to Auth service
- Simple API key authentication using environment variables

### Security Model
This implementation uses an **open trust model** suitable for internal services:
- Services with valid API keys can access any user data
- No request-level authorization (e.g., checking if classroom service should access specific students)
- Designed for simplicity and speed at current scale (hundreds of students)
- Assumes services run in a trusted environment with secure API key storage
- Appropriate for internal microservices where all services are trusted

### Service API Keys
Currently configured service keys (in development):
- `CLASSROOM_SERVICE_API_KEY` (default: `classroom_service_key_123`)
- `GAME_SERVICE_API_KEY` (default: `game_service_key_456`)
- `STORE_SERVICE_API_KEY` (default: `store_service_key_789`)

### Example: Classroom App Integration
```ruby
# In downstream Classroom app's schema:
create_table :classes, id: :uuid do |t|
  t.string :name
  t.uuid :teacher_id  # references Auth.external_id
end

create_table :enrollments, id: :uuid do |t|
  t.uuid :class_id
  t.uuid :student_id  # references Auth.external_id
end

# To fetch student data:
# GET /api/v1/services/users?external_ids[]=uuid1&external_ids[]=uuid2
# Header: X-Service-Api-Key: classroom_service_key_123
```

## Important Configuration Notes

- Application started as API-only but modified to support admin views
- Added middleware: cookies, sessions, flash (see `config/application.rb`)
- CORS configured for localhost:3000, 3001, 3002
- MySQL with string-based UUIDs (not native UUID type)
- Service authentication uses simple API keys (suitable for internal services)