# Cranston Auth API - Deployment Guide

This guide is for IT administrators deploying the Cranston Auth API using Docker.

## Prerequisites

- Docker Engine 20.10+ installed
- Docker Compose 2.0+ installed
- At least 2GB RAM available
- Port 3000 (web) and 3306 (database) available

## Quick Start

1. **Configure Environment Variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and set:
   - `MYSQL_ROOT_PASSWORD`: Strong password for MySQL root user
   - `MYSQL_PASSWORD`: Password for the application database user
   - `RAILS_MASTER_KEY`: Copy the content from `config/master.key` (provided separately)
   - Service API keys for downstream applications

2. **Build and Start Containers**
   ```bash
   docker-compose up -d --build
   ```
   This will:
   - Build the Rails application image
   - Start MySQL database container
   - Start Rails application container
   - Create the database and run migrations automatically

3. **Verify Installation**
   ```bash
   # Check container status
   docker-compose ps
   
   # Check application logs
   docker-compose logs -f web
   
   # Test the health endpoint
   curl http://localhost:3000/up
   ```

## Initial Admin Setup

1. **Create Initial Admin User**
   ```bash
   docker-compose exec web rails console
   ```
   Then in the Rails console:
   ```ruby
   User.create!(
     email: "admin@your-school.edu",
     password: "secure_password_here",
     role: "admin",
     first_name: "System",
     last_name: "Administrator"
   )
   exit
   ```

2. **Access Admin Interface**
   - Navigate to: http://your-server:3000/admin/login
   - Login with the admin credentials created above

## Container Management

### Start/Stop Services
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart a specific service
docker-compose restart web
docker-compose restart db
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f db
```

### Access Rails Console
```bash
docker-compose exec web rails console
```

### Run Database Migrations
```bash
docker-compose exec web rails db:migrate
```

### Database Backup
```bash
# Backup database to file
docker-compose exec db mysqldump -u root -p cranston_auth_production > backup_$(date +%Y%m%d).sql

# Restore from backup
docker-compose exec -T db mysql -u root -p cranston_auth_production < backup_20240101.sql
```

## Production Configuration

### SSL/TLS Setup
For production, place this application behind a reverse proxy (nginx/Apache) with SSL certificates.

Example nginx configuration:
```nginx
server {
    listen 443 ssl;
    server_name auth.your-school.edu;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Backup Strategy
1. **Automated Daily Backups**
   Create a cron job for daily database backups:
   ```bash
   0 2 * * * docker-compose exec -T db mysqldump -u root -p$MYSQL_ROOT_PASSWORD cranston_auth_production > /backups/cranston_auth_$(date +\%Y\%m\%d).sql
   ```

2. **Persistent Data**
   The MySQL data is stored in a Docker volume. To backup the entire volume:
   ```bash
   docker run --rm -v cranston_auth_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_data_backup.tar.gz /data
   ```

## Monitoring

### Health Checks
- Application health: `GET http://localhost:3000/up`
- Database health: MySQL is monitored via Docker's built-in healthcheck

### Resource Usage
```bash
# Check container resource usage
docker stats

# Check disk usage
docker system df
```

## Troubleshooting

### Application Won't Start
1. Check logs: `docker-compose logs web`
2. Verify master key is set correctly in `.env`
3. Ensure database is running: `docker-compose ps db`

### Database Connection Issues
1. Check database logs: `docker-compose logs db`
2. Verify database credentials in `.env`
3. Test connection: `docker-compose exec web rails db:migrate`

### Reset Everything
```bash
# Stop and remove all containers and volumes (WARNING: Deletes all data!)
docker-compose down -v

# Start fresh
docker-compose up -d --build
```

## Security Notes

1. **Never commit `.env` file** - It contains sensitive credentials
2. **Rotate API keys regularly** - Update service API keys in `.env` and restart
3. **Keep Docker updated** - Regular security updates are important
4. **Network isolation** - Consider using Docker networks to isolate services
5. **Firewall rules** - Only expose necessary ports (3000 for web interface)

## Service Integration

Downstream services (classroom app, game app, etc.) should connect using:
- Endpoint: `http://your-server:3000/api/v1/services/*`
- Header: `X-Service-Api-Key: [service-specific-key-from-env]`

## Support

For application-specific issues, refer to:
- `/CLAUDE.md` - Application documentation
- `/README.md` - Development documentation

For deployment issues, check Docker logs first, then contact your development team.