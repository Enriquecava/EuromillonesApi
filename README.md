# EuromillonesApi

**Version 1.2.0** - REST API for querying Euromillones lottery results with authentication and security validation.

## 🆕 What's New in v1.2.0

- **Enhanced Quality Gates**: Comprehensive pre-commit hooks with Overcommit
- **Complete Test Suite**: Full RSpec test coverage for all endpoints
- **CI/CD Pipeline**: GitHub Actions with automated testing and security audits
- **Branch Protection**: Multi-level protection with automated quality checks
- **Security Improvements**: Enhanced validation and Row Level Security (RLS)

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

# Run tests for changed files only (optimized)
rake test_changed
```

### Pre-commit Hooks

This project uses [Overcommit](https://github.com/sds/overcommit) to run tests automatically before commits and pushes:

```bash
# Install git hooks (one-time setup)
rake install_hooks

# Or use the development setup task
rake dev:setup
```

**What happens on commit (fast feedback):**
- ✅ Tests for changed files only
- ✅ Ruby syntax validation
- ✅ YAML/JSON syntax validation
- ✅ Merge conflict detection
- ✅ Commit message format validation

**What happens on push (quality gate):**
- ✅ Full RSpec test suite
- ✅ Complete validation before code reaches remote

**GitHub Actions (CI/CD):**
- ✅ Runs on PRs targeting `main` or `devel` branches
- ✅ Runs on pushes to `main` or `devel` branches
- ✅ Full test suite with PostgreSQL
- ✅ Security audit and code quality checks

**To bypass hooks temporarily (emergencies only):**
```bash
git commit --no-verify -m "Emergency fix"
git push --no-verify
```

For detailed setup instructions, see [`docs/OVERCOMMIT_SETUP.md`](docs/OVERCOMMIT_SETUP.md).

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

## 🔄 CI/CD & Branch Protection

The project includes comprehensive CI/CD with multi-level protection:

### Local Protection (Pre-commit Hooks)
- **Overcommit gem** runs tests before commits
- **Syntax validation** for Ruby files
- **Code quality checks** (whitespace, line endings)
- **Commit message validation**

### Remote Protection (GitHub Actions)
- **Automated tests** on every PR
- **Linting** and syntax validation
- **Security audit** with bundler-audit
- **PostgreSQL database setup** for tests
- **Branch protection validation**

### Branch Protection Rules
- **main**: Requires PR + 1 approval + all status checks + code owner review
- **devel**: Requires PR + all status checks + 1 approval
- **feature branches**: No restrictions

### Workflows

```yaml
# .github/workflows/ci.yml
- Tests with PostgreSQL
- Ruby syntax validation
- Security audit
- Branch protection validation

# .github/workflows/pre-commit.yml
- Pre-commit hooks validation
- Changed files analysis
- Commit message validation
```

For detailed branch protection setup, see [`BRANCH_PROTECTION_SETUP.md`](BRANCH_PROTECTION_SETUP.md).

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

### Development Workflow

1. **Setup development environment:**
   ```bash
   git clone https://github.com/your-username/EuromillonesApi.git
   cd EuromillonesApi
   bundle install
   rake dev:setup  # Installs git hooks automatically
   ```

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Develop with automatic testing:**
   ```bash
   # Edit your code
   # Tests run automatically on commit via pre-commit hooks
   git add .
   git commit -m "Add amazing feature"
   ```

4. **Push and create PR:**
   ```bash
   git push origin feature/amazing-feature
   # Create PR to 'devel' branch (not main directly)
   ```

5. **Merge flow:**
   ```
   feature/branch → devel → main
   ```

### Code Standards

- **Follow Ruby conventions** and style guides
- **Add tests for new features** - pre-commit hooks enforce this
- **Maintain high test coverage** - CI checks this automatically
- **Document API changes** in swagger.yaml
- **Use descriptive commit messages** - enforced by commit hooks
- **Keep PRs focused** - one feature per PR

### Pre-commit Hooks

The project automatically runs these checks before each commit:
- ✅ **RSpec tests** - ensures your changes don't break existing functionality
- ✅ **Ruby syntax** - catches syntax errors before they reach CI
- ✅ **Code formatting** - maintains consistent style
- ✅ **Commit message format** - ensures clear commit history

### Bypassing Hooks (Emergency Only)

```bash
# Only use in genuine emergencies
git commit --no-verify -m "Emergency hotfix"
```

### Available Rake Tasks

```bash
rake test              # Run all tests
rake test_changed      # Run tests for changed files only
rake install_hooks     # Install/reinstall git hooks
rake dev:setup         # Complete development setup
rake ci:test           # Run CI test suite locally
rake ci:security       # Run security audit
```

## 📝 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## 📞 Support

If you have questions or issues:

1. Check the documentation at `/docs`
2. Search existing issues
3. Create a new issue with problem details

---

**Thanks for using EuromillonesApi!** 🎰✨
