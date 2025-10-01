# EuromillonesApi

REST API for querying Euromillones lottery results with authentication and security validation.

## 🚀 Features

- **Complete REST API** for user management and results consultation
- **Basic Auth authentication** with bcrypt
- **Security validation** against SQL injection, XSS and other attacks
- **Rate limiting** and content validation
- **Interactive Swagger/OpenAPI documentation**
- **PostgreSQL database** with Row Level Security (RLS)
- **Automated scraper** to fetch official results
- **RSpec testing** and CI/CD with GitHub Actions

## 📋 Requirements

- Ruby 3.1+
- PostgreSQL 13+
- Bundler

## 🛠️ Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/EuromillonesApi.git
cd EuromillonesApi
```

2. Install dependencies:
```bash
bundle install
```

3. Setup the database:
```bash
# Create database and run migrations
rake db:create
rake db:migrate
```

4. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your configurations
```

## 🚦 Usage

### Development

```bash
# Start development server
ruby app.rb

# Server will be available at http://localhost:4567
```

### Testing

```bash
# Run all tests
bundle exec rspec

# Run specific tests
bundle exec rspec spec/requests/results_spec.rb

# Run tests with detailed format
bundle exec rspec --format documentation
```

### API Documentation

Visit `http://localhost:4567/docs` to access the interactive Swagger UI documentation.

## 📚 Endpoints

### System
- `GET /health` - System status
- `GET /docs` - Swagger UI documentation

### Users
- `POST /user` - Create user
- `GET /user` - Get authenticated user information

### Results
- `GET /results/:date` - Get result by date (YYYY-MM-DD)

### Combinations
- `POST /combinations` - Create combination
- `GET /combinations` - List user combinations
- `PUT /combinations/:id` - Update combination
- `DELETE /combinations/:id` - Delete combination

## 🔐 Authentication

The API uses Basic Authentication:

```bash
curl -u "your_nickname:your_password" http://localhost:4567/user
```

## 🧪 Testing

The project includes a comprehensive test suite with RSpec:

- **Integration tests** for endpoints
- **Security validation tests**
- **Database mocking** for isolated tests
- **CI/CD** with GitHub Actions

### Test Structure

```
spec/
├── spec_helper.rb          # RSpec configuration
├── requests/               # Endpoint tests
│   └── results_spec.rb     # Tests for /results endpoint
├── middleware/             # Middleware tests
└── support/                # Helpers and configuration
```

### Running Tests

```bash
# All tests
bundle exec rspec

# Specific tests
bundle exec rspec spec/requests/results_spec.rb

# With coverage
bundle exec rspec --format html --out coverage/index.html
```

## 🔄 CI/CD

The project includes GitHub Actions for:

- **Automated tests** on every PR
- **Linting** and syntax validation
- **Security audit** with bundler-audit
- **PostgreSQL database setup** for tests

### Workflow

```yaml
# .github/workflows/ci.yml
- Tests with PostgreSQL
- Ruby syntax validation
- Security audit
- Report generation
```

## 🗃️ Database

### Main Schema

```sql
-- Users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lottery results
CREATE TABLE results (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    bolas JSONB NOT NULL,
    stars JSONB NOT NULL,
    jackpot JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User combinations
CREATE TABLE combinations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    name VARCHAR(100) NOT NULL,
    balls JSONB NOT NULL,
    stars JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🛡️ Security

- **Input validation** against SQL injection and XSS
- **Rate limiting** (100 requests/minute)
- **Required authentication** for protected endpoints
- **Row Level Security (RLS)** in PostgreSQL
- **Input sanitization** for all inputs
- **Security event logging**

## 📊 Logging

The system includes structured logging:

```ruby
# Application logs
AppLogger.info("User authenticated", "AUTH")
AppLogger.error("Database error", "DB")

# Validation logs
AppLogger.log_validation_error("email", value, "Invalid format")
```

## 🔧 Configuration

### Environment Variables

```bash
# Database
DATABASE_URL=postgres://user:pass@localhost/euromillones_api

# Application
APP_ENV=development
LOG_LEVEL=info
PORT=4567

# Rate limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
```

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards

- Follow Ruby conventions
- Add tests for new features
- Maintain high test coverage
- Document API changes

## 📝 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## 📞 Support

If you have questions or issues:

1. Check the documentation at `/docs`
2. Search existing issues
3. Create a new issue with problem details

---

**Thanks for using EuromillonesApi!** 🎰✨
