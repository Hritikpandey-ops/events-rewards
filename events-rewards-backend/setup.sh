#!/bin/bash

# Events & Rewards Backend Setup Script
echo " Setting up Events & Rewards Backend with Docker PostgreSQL..."

# Create project directory structure
echo " Creating project structure..."
mkdir -p events-rewards-backend
cd events-rewards-backend

# Create directory structure
mkdir -p cmd/server
mkdir -p internal/{config,handlers,middleware,models,repositories,services}
mkdir -p pkg/utils
mkdir -p migrations
mkdir -p uploads/{selfies,audio}

# Set permissions for upload directories
chmod 755 uploads/{selfies,audio}

# Copy/create necessary files
echo " Creating configuration files..."

# Create .env file
cat > .env << 'EOF'
PORT=8080
DATABASE_URL=postgres://events_user:events_password@localhost:5432/events_rewards?sslmode=disable
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-please
UPLOAD_PATH=./uploads
EOF

# Create docker-compose.yml
echo " Creating Docker Compose configuration..."
# (Docker compose content would be here)

# Create migration file
echo " Creating database migration..."
# (Migration SQL would be here)

# Start PostgreSQL with Docker
echo " Starting PostgreSQL with Docker..."
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo " Waiting for PostgreSQL to be ready..."
sleep 10

# Check if PostgreSQL is running
if docker-compose ps postgres | grep -q "Up"; then
    echo " PostgreSQL is running successfully!"
    echo " pgAdmin will be available at: http://localhost:5050"
    echo "   Email: admin@admin.com"
    echo "   Password: admin"
    echo ""
    echo " Database connection details:"
    echo "   Host: localhost"
    echo "   Port: 5432"
    echo "   Database: events_rewards"
    echo "   Username: events_user"
    echo "   Password: events_password"
else
    echo " Failed to start PostgreSQL. Please check Docker logs:"
    docker-compose logs postgres
    exit 1
fi

# Initialize Go module
echo " Initializing Go module..."
go mod init events-rewards-backend

# Install dependencies
echo " Installing Go dependencies..."
go mod tidy

echo ""
echo "  Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Copy your Go source files to the appropriate directories"
echo "2. Run: go mod tidy"
echo "3. Run: go run cmd/server/main.go"
echo ""
echo "  Docker commands:"
echo "  Start services: docker-compose up -d"
echo "  Stop services: docker-compose down"
echo "  View logs: docker-compose logs"
echo "  Access database: docker exec -it events_rewards_db psql -U events_user -d events_rewards"
