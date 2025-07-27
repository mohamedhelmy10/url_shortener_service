# URL Shortener Service - Setup Instructions

This document provides detailed instructions for setting up and running the URL Shortener Service assessment project.

## Prerequisites

Before running this application, ensure you have the following installed:

- **Ruby** (version 3.4.5)
- **Rails** (version 8.0.2)
- **PostgreSQL** (version 12 or higher, version 14+ recommended)

### Checking Your Environment

```bash
# Check Ruby version
ruby --version
# Check Rails version
rails --version
# Check PostgreSQL version (multiple methods)
psql --version
# OR
sudo -u postgres psql -c "SELECT version();"
# OR
pg_config --version
```

## Project Structure

Understanding the codebase organization will help you navigate and work with the application:

```
url_shortener_service/
├── app/
│   ├── controllers/
│   │   └── short_urls_controller.rb    # API endpoints for encode/decode
│   ├── models/
│   │   └── short_url.rb                # Database model with validations
│   └── services/
│       └── url_shortening_service.rb   # Business logic for URL shortening
├── config/
│   ├── routes.rb                       # URL routing configuration
│   └── database.yml                    # Database configuration
├── db/
│   ├── migrate/                        # Database migration files
│   └── schema.rb                       # Current database schema
├── spec/
│   ├── factories/                      # Test data factories
│   ├── models/                         # Model unit tests
│   ├── services/                       # Service unit tests
│   └── requests/                       # API endpoint tests
├── Gemfile                             # Ruby dependencies
├── README.md                           # Project overview and API docs
└── SETUP_INSTRUCTIONS.md               # This setup guide
```

### Key Files Explained

- **`app/controllers/short_urls_controller.rb`**: Handles HTTP requests for encoding and decoding URLs
- **`app/models/short_url.rb`**: Defines the database model with validations and callbacks
- **`app/services/url_shortening_service.rb`**: Contains the core business logic for URL shortening
- **`config/routes.rb`**: Defines the API endpoints (`/encode`, `/decode`, `/:short_code`)
- **`spec/`**: Contains all test files organized by type (models, services, requests)

## Why These Prerequisites Are Needed

### PostgreSQL
- **Purpose**: Database for storing short URLs and their codes
- **Why needed**: Rails uses PostgreSQL as the primary database for this application
- **Version requirement**: PostgreSQL 12+ (version 14+ recommended for better performance and features)
- **Compatibility**: Rails 8.0 works with PostgreSQL 12, 13, 14, 15, and 16

### Ruby & Rails
- **Purpose**: Core framework for the API application
- **Why needed**: This is a Rails API application that provides URL shortening functionality
- **Version requirement**: Ruby 3.4.5 and Rails 8.0.2 for latest features and security

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/mohamedhelmy10/url_shortener_service.git
cd url_shortener_service
```

### Step 2: Install Ruby Dependencies

```bash
bundle install
```

#### Bundle Installation Troubleshooting

If you encounter issues with `bundle install`:

**1. Update Bundler:**
```bash
gem update bundler
gem install bundler
```

**2. Clear Bundle Cache:**
```bash
bundle clean --force
bundle install --clean
```

**3. Install System Dependencies (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install build-essential libpq-dev libssl-dev zlib1g-dev
```

**4. Install System Dependencies (macOS):**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install PostgreSQL development headers
brew install postgresql
```

### Step 3: Environment Configuration

Create a `.env` file in the root directory:

```bash
# Copy the example environment file
cp .env.example .env
```

Then edit the `.env` file and fill in your database credentials and other configuration.

### Step 4: Configure Database

Create and configure your database:

```bash
# Create the database
rails db:create

# Run migrations
rails db:migrate

# Verify database setup
rails db:version
```

## Running the Application

### Start the Development Server

```bash
rails server
```

The application will be available at `http://localhost:3000`

### Alternative: Using a Different Port

If port 3000 is already in use:

```bash
rails server -p 3001
```

## Testing the Application

### Run All Tests

```bash
bundle exec rspec
```

### Run Specific Test Suites

```bash
# Model tests
bundle exec rspec spec/models/

# Service tests
bundle exec rspec spec/services/

# Request/API tests
bundle exec rspec spec/requests/
```

### Run Individual Test Files

```bash
# ShortUrl model tests
bundle exec rspec spec/models/short_url_spec.rb

# UrlShorteningService tests
bundle exec rspec spec/services/url_shortening_service_spec.rb

# API endpoint tests
bundle exec rspec spec/requests/short_urls_spec.rb
```

## API Usage Examples

### 1. Encode a URL

**Request:**
```bash
curl -X POST http://localhost:3000/encode \
  -H "Content-Type: application/json" \
  -d '{
    "short_url": {
      "original_url": "https://example.com/very/long/url/that/needs/shortening"
    }
  }'
```

**Expected Response:**
```json
{
  "short_url": "http://localhost:3000/abc123"
}
```

### 2. Decode a Short Code

**Request:**
```bash
curl -X GET "http://localhost:3000/decode?short_code=abc123"
```

**Expected Response:**
```json
{
  "original_url": "https://example.com/very/long/url/that/needs/shortening"
}
```

## Using the Rails Console

### Start the Console

```bash
rails console
```

### Example Commands

```ruby
# Encode a URL
result = UrlShorteningService.encode("https://example.com")
puts result[:short_url].short_code

# Decode a short code
short_url = UrlShorteningService.decode("abc123")
puts short_url.original_url if short_url

# Create a short URL manually
short_url = ShortUrl.create(original_url: "https://test.com")
puts short_url.short_code
```

## Support

If you continue to experience issues after following these instructions:

1. Check the Rails documentation: https://guides.rubyonrails.org/
2. Review the RSpec documentation: https://rspec.info/
3. Consult the PostgreSQL documentation: https://www.postgresql.org/docs/

---

**Note**: This setup guide assumes a Unix-like environment (Linux/macOS). Windows users may need to adjust some commands accordingly. 
