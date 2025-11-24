#!/bin/bash
set -e

# IDaaS Platform Deployment Script
# This script helps deploy the IDaaS platform in different environments

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    # Check if docker-compose is installed
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is not installed. Please install docker-compose first."
        exit 1
    fi

    print_info "Prerequisites check passed!"
}

# Function to check environment variables
check_env_vars() {
    print_info "Checking required environment variables..."

    if [ "$DEPLOYMENT_MODE" == "production" ]; then
        required_vars=(
            "POSTGRES_PASSWORD"
            "KEYCLOAK_ADMIN_PASSWORD"
            "SECRET_KEY"
            "OAUTH2_CLIENT_SECRET"
            "OAUTH2_COOKIE_SECRET"
            "KEYCLOAK_HOSTNAME"
            "APP_HOSTNAME"
        )

        missing_vars=()
        for var in "${required_vars[@]}"; do
            if [ -z "${!var}" ]; then
                missing_vars+=("$var")
            fi
        done

        if [ ${#missing_vars[@]} -ne 0 ]; then
            print_error "Missing required environment variables for production deployment:"
            for var in "${missing_vars[@]}"; do
                echo "  - $var"
            done
            print_error "Please set these variables in your .env file or environment."
            exit 1
        fi

        # Check cookie secret length
        cookie_len=${#OAUTH2_COOKIE_SECRET}
        if [ $cookie_len -ne 16 ] && [ $cookie_len -ne 24 ] && [ $cookie_len -ne 32 ]; then
            print_error "OAUTH2_COOKIE_SECRET must be exactly 16, 24, or 32 bytes. Current length: $cookie_len"
            exit 1
        fi
    fi

    print_info "Environment variables check passed!"
}

# Function to load environment variables
load_env() {
    if [ -f .env ]; then
        print_info "Loading environment variables from .env file..."
        export $(grep -v '^#' .env | xargs)
    else
        print_warn ".env file not found. Using environment variables or defaults."
    fi
}

# Function to deploy
deploy() {
    local mode=$1

    print_info "Starting deployment in $mode mode..."

    if [ "$mode" == "production" ]; then
        print_info "Deploying with production configuration..."
        docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
    elif [ "$mode" == "development" ]; then
        print_info "Deploying with development configuration..."
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
    else
        print_info "Deploying with default configuration..."
        docker-compose up -d --build
    fi

    print_info "Waiting for services to start..."
    sleep 10

    print_info "Checking service health..."
    docker-compose ps
}

# Function to show status
show_status() {
    print_info "Service Status:"
    docker-compose ps

    print_info "\nService Logs (last 20 lines):"
    docker-compose logs --tail=20
}

# Function to stop services
stop_services() {
    print_info "Stopping services..."
    docker-compose down
    print_info "Services stopped!"
}

# Function to clean up
cleanup() {
    print_warn "This will remove all containers, volumes, and data. Are you sure? (yes/no)"
    read -r confirmation

    if [ "$confirmation" == "yes" ]; then
        print_info "Cleaning up..."
        docker-compose down -v
        print_info "Cleanup complete!"
    else
        print_info "Cleanup cancelled."
    fi
}

# Function to show logs
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$service"
    fi
}

# Function to run tests
run_tests() {
    print_info "Running tests..."

    cd apps/webapp

    if [ ! -d "venv" ]; then
        print_info "Creating virtual environment..."
        python3 -m venv venv
        venv/bin/pip install --upgrade pip
        venv/bin/pip install -r requirements.txt
    fi

    print_info "Running unit tests..."
    venv/bin/pytest tests/ -v

    print_info "Running security scans..."
    venv/bin/bandit -r . --exclude ./venv,./tests -f txt

    cd ../..

    print_info "Tests complete!"
}

# Main script
main() {
    case "$1" in
        deploy)
            check_prerequisites
            load_env
            check_env_vars
            deploy "${DEPLOYMENT_MODE:-default}"
            show_status
            print_info "Deployment complete!"
            print_info "Access the application at: http://localhost:4180 (or your configured domain)"
            ;;
        status)
            show_status
            ;;
        stop)
            stop_services
            ;;
        cleanup)
            cleanup
            ;;
        logs)
            show_logs "$2"
            ;;
        test)
            run_tests
            ;;
        *)
            echo "IDaaS Platform Deployment Script"
            echo ""
            echo "Usage: $0 {deploy|status|stop|cleanup|logs|test}"
            echo ""
            echo "Commands:"
            echo "  deploy  - Deploy the platform (reads DEPLOYMENT_MODE from .env)"
            echo "  status  - Show service status and logs"
            echo "  stop    - Stop all services"
            echo "  cleanup - Stop services and remove all data (WARNING: destructive)"
            echo "  logs    - Show logs (optionally specify service name)"
            echo "  test    - Run tests and security scans"
            echo ""
            echo "Examples:"
            echo "  $0 deploy              # Deploy based on .env configuration"
            echo "  $0 status              # Show current status"
            echo "  $0 logs webapp         # Show webapp logs"
            echo "  $0 test                # Run all tests"
            exit 1
            ;;
    esac
}

main "$@"
