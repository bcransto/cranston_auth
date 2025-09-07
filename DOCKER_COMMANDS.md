# Docker Commands Quick Reference

## Container Management

### Check Status
```bash
# See running containers
docker-compose ps

# See all containers (including stopped)
docker ps -a

# View logs
docker-compose logs -f        # All services
docker-compose logs -f web     # Just Rails app
docker-compose logs -f db      # Just MySQL
```

### Start/Stop
```bash
# Start containers
docker-compose up -d

# Stop containers (data persists)
docker-compose down

# Stop and remove volumes (DELETE ALL DATA)
docker-compose down -v

# Restart a service
docker-compose restart web
```

## Working with the Rails App

### Rails Console
```bash
docker-compose exec web rails console
```

### Run Migrations
```bash
docker-compose exec web rails db:migrate
```

### Create Admin User
```bash
docker-compose exec web rails console
```
Then in console:
```ruby
User.create!(
  email: "admin@test.edu",
  password: "password123",
  role: "admin",
  first_name: "Test",
  last_name: "Admin"
)
```

### Run Any Rails Command
```bash
docker-compose exec web rails [command]
```

## Database Access

### Access MySQL Console
```bash
docker-compose exec db mysql -u cranston_auth -p
# Password: test_db_password_456
```

### Backup Database
```bash
docker-compose exec db mysqldump -u root -ptest_root_password_123 cranston_auth_production > backup.sql
```

### Restore Database
```bash
docker-compose exec -T db mysql -u root -ptest_root_password_123 cranston_auth_production < backup.sql
```

## Testing the Application

### Check Health
```bash
curl http://localhost:3000/up
```

### Test API Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.edu","password":"password123"}'
```

### Test Service API
```bash
# Get user by external ID
curl -X GET http://localhost:3000/api/v1/services/users/{external_id} \
  -H "X-Service-Api-Key: classroom_test_key_789"

# Note: The API key must match one of these environment variables:
# CLASSROOM_SERVICE_API_KEY=classroom_test_key_789
# GAME_SERVICE_API_KEY=game_test_key_101
# STORE_SERVICE_API_KEY=store_test_key_112
```

## Troubleshooting

### View Real-time Logs
```bash
docker-compose logs -f --tail=50
```

### Rebuild Containers
```bash
docker-compose build --no-cache
docker-compose up -d
```

### Check Container Resource Usage
```bash
docker stats
```

### Access Container Shell
```bash
docker-compose exec web bash
docker-compose exec db bash
```

### Remove All Docker Data (Nuclear Option)
```bash
docker-compose down -v
docker system prune -a
```

## URLs to Access

- **Admin Interface**: http://localhost:3000/admin/login
- **API Health Check**: http://localhost:3000/up
- **MySQL**: localhost:3306 (user: cranston_auth, password: test_db_password_456)