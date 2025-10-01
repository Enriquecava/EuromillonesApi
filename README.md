# EuromillonesApi

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/your-username/EuromillonesApi/releases/tag/v1.1.0)
[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A REST API built with Ruby and Sinatra for querying Euromillions lottery results and managing users with their favorite number combinations.

> **🔐 Version 1.1.0 Released!** - Enhanced security with Row Level Security (RLS) and Basic Authentication. **BREAKING CHANGES**: All endpoints now require authentication.

## 📋 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Endpoints](#api-endpoints)
- [Interactive API Documentation (Swagger UI)](#-interactive-api-documentation-swagger-ui)
- [Logging System](#-logging-system)
- [Scraper](#scraper)
- [Project Structure](#project-structure)
- [Validations](#validations)
- [Contributing](#contributing)

## ✨ Features

- 🎲 Query historical Euromillions results by date
- 👥 Complete user management (CRUD operations)
- 🎯 Number combination management per user
- 🕷️ Automated web scraper for fetching results
- 🏥 Health check endpoint
- 📊 JSON response format
- 🛡️ Robust error handling
- ✅ Data validation with proper error messages
- 📖 **Interactive API documentation with Swagger UI**
- 🧪 **Built-in testing interface for all endpoints**
- 📝 **Comprehensive logging system with request tracking**
- 🔍 **Monitoring and debugging capabilities**
- 🔐 **Basic Authentication required for all endpoints**
- 🛡️ **Row Level Security (RLS) for database-level protection**
- 🔒 **Automatic user context isolation**
- 🔑 **bcrypt password hashing for secure credential storage**

## 🚀 Installation

### Prerequisites

- Ruby 3.0+
- PostgreSQL
- Node.js and npm (for Playwright)
- Bundler

### Installation Steps

1. **Clone the repository**
```bash
git clone https://github.com/your-username/EuromillonesApi.git
cd EuromillonesApi
```

2. **Install Ruby dependencies**
```bash
bundle install
```

3. **Install Playwright**
```bash
npx playwright install
```

4. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your database credentials
```

5. **Set up database**
```bash
# Create database and required tables
# (See configuration section)
```

## ⚙️ Configuration

### Environment Variables (.env)

```env
# Database Configuration
PG_HOST=localhost
PG_PORT=5432
PG_DB=euromillones_db
PG_USER=your_username
PG_PASSWORD=your_password

# Application Configuration
APP_ENV=development          # development, production, test
APP_PORT=4567

# Logging Configuration
LOG_LEVEL=debug             # debug, info, warn, error, fatal
```

### Database Schema

> 📄 **Complete script:** See [docs/DATABASE_SCHEMA.sql](docs/DATABASE_SCHEMA.sql)

Main tables:
- `users` - User information
- `combinations` - Number combinations per user
- `results` - Historical lottery results
- `credentials` - User authentication credentials (bcrypt hashed)

### 🔐 Security Features

> **⚠️ BREAKING CHANGES in v1.1.0**: All API endpoints now require Basic Authentication

- **Row Level Security (RLS)** - Database-level data isolation
- **Basic Authentication** - Required for all endpoints except system routes
- **bcrypt Password Hashing** - Secure credential storage
- **Automatic User Context** - RLS policies enforce data access by authenticated user
- **Database-level Protection** - Even if application code has vulnerabilities, data is protected

### Authentication Setup

1. **Create user credentials** (see migration script in `docs/DATABASE_SCHEMA.sql`)
2. **Use Basic Auth header**: `Authorization: Basic <base64(username:password)>`
3. **Example**: `Authorization: Basic ZXVyb21pbGxvbmVzUmFmZmxlOmtpb2tlbmNhdmExNA==`

## 🎯 Usage

### Start the server

```bash
bundle exec ruby app.rb
```

The server will be available at `http://localhost:4567`

### Run the scraper

```bash
bundle exec ruby scrapper/scrapper.rb 2024-01-15
```

## 📚 API Endpoints

### 🏠 System
- `GET /` - General API information
- `GET /health` - Service health check

### 🎲 Euromillions Results
- `GET /results/:date` - Get result by date (YYYY-MM-DD)

### 👥 User Management
- `POST /user` - Create new user
- `GET /user/:email` - Get user information
- `PUT /user/:email` - Update user email
- `DELETE /user/:email` - Delete user

### 🎯 Combination Management
- `POST /combinations` - Create new combination
- `GET /combinations/:email` - Get user combinations
- `PUT /combinations/:id` - Update combination
- `DELETE /combinations/:id` - Delete combination

> 📖 **For detailed usage examples:** See [docs/API_EXAMPLES.md](docs/API_EXAMPLES.md)

## 📖 Interactive API Documentation (Swagger UI)

La API incluye documentación interactiva completa con Swagger UI que permite probar todos los endpoints directamente desde el navegador.

### 🚀 Acceso a la documentación

Una vez que el servidor esté ejecutándose, accede a:

- **Swagger UI**: http://localhost:4567/docs
- **Especificación JSON**: http://localhost:4567/swagger.json
- **Especificación YAML**: http://localhost:4567/swagger.yaml

### ✨ Características de Swagger UI

- 🧪 **Interfaz de pruebas interactiva** - Ejecuta peticiones directamente
- 📋 **Documentación completa** - Todos los endpoints, parámetros y respuestas
- 🔍 **Casos de prueba incluidos** - Ejemplos con datos válidos e inválidos
- 🛠️ **Generación automática de código** - Comandos curl listos para usar
- ✅ **Validación en tiempo real** - Respuestas reales de la API

### 🧪 Casos de prueba documentados

- ✅ **Operaciones exitosas** con datos válidos
- ❌ **Validación de errores** con datos faltantes/inválidos (emails, IDs, etc.)
- 🔄 **Flujos completos** de usuario (crear usuario → añadir combinaciones)

### 📊 Endpoints organizados por categorías

- **System** - Información del sistema y health checks
- **Results** - Consulta de resultados de Euromillones
- **Users** - Gestión completa de usuarios (CRUD)
- **Combinations** - Gestión de combinaciones de lotería

> 💡 **Tip**: Use Swagger UI to explore the API and test different scenarios, including cases with missing or invalid data.

## 📝 Logging System

The API includes a comprehensive logging system that records all operations, errors, and performance metrics.

### 🚀 Logging Features

- ✅ **Automatic HTTP request logging** with timing and status codes
- ✅ **Module-based logging** (USERS, COMBINATIONS, RESULTS, SYSTEM, SCRAPER)
- ✅ **Multiple log levels** (DEBUG, INFO, WARN, ERROR, FATAL)
- ✅ **Automatic log rotation** (daily in production)
- ✅ **Structured format** with timestamps and categories
- ✅ **Database error logging** with full context
- ✅ **Validation error logging** for debugging

### 📊 Log Examples

```
[2025-09-29 13:52:48] INFO  STARTUP: Euromillones API starting up
[2025-09-29 13:52:48] INFO  STARTUP: Environment: development
[2025-09-29 13:52:50] DEBUG HTTP: Request started: GET /health
[2025-09-29 13:52:50] INFO  SYSTEM: Health check passed - database is reachable
[2025-09-29 13:52:50] INFO  HTTP: GET /health -> 200 (0.031s)
```

### ⚙️ Log Configuration

Logs are automatically configured based on environment:

- **development**: Console output with DEBUG level
- **production**: `log/app.log` file with daily rotation
- **test**: Separate `log/test.log` file

### 📁 Log Location

```
log/
├── app.log         # Production logs
├── test.log        # Test logs
└── *.log.YYYYMMDD  # Rotated files
```

## 🕷️ Scraper

The automated scraper fetches results from the official website.

### Scraper Usage

```bash
# Get result for a specific date
bundle exec ruby scrapper/scrapper.rb 2024-01-15
```

### Scraper Features

- 🎭 Uses Playwright for web navigation
- 🔄 Automatically updates existing results
- 📊 Extracts numbers, stars, and prizes
- 🛡️ Page Object Model for maintainability

## 📁 Project Structure

```
EuromillonesApi/
├── app.rb                      # Main application
├── db.rb                       # Database configuration
├── Gemfile                     # Ruby dependencies
├── README.md                   # Documentation
├── swagger.yaml                # OpenAPI/Swagger specification
├── .env                        # Environment variables
├── lib/                        # Shared libraries
│   ├── validators.rb          # Data validation helpers
│   └── app_logger.rb          # Logging system
├── routes/                     # Organized endpoints
│   ├── system.rb              # System endpoints
│   ├── users.rb               # User management
│   ├── euromillones.rb        # Lottery results
│   └── combinations.rb        # Combination management
├── scrapper/                   # Automated scraper
│   ├── scrapper.rb            # Main script
│   └── pom/                   # Page Object Model
│       └── lottery_page.rb    # Web page interaction
├── bruno/                      # Bruno API testing collection
│   └── Euromillones/          # Test cases for all endpoints
├── docs/                       # Documentation
│   ├── API_EXAMPLES.md        # Usage examples
│   ├── DATABASE_SCHEMA.sql    # Database setup
│   └── VALIDATION_IMPLEMENTATION.md  # Validation details
├── log/                        # Log files
│   ├── app.log                # Production logs
│   └── test.log               # Test logs
└── config/
    └── database.yml           # DB configuration
```

## ✅ Validations

### Data Validations
- **Combinations**: 5 balls (1-50) and 2 stars (1-12)
- **Dates**: YYYY-MM-DD format, no future dates
- **Emails**: Valid format and unique
- **No duplicates**: Within balls or stars arrays

### HTTP Status Codes
- `200` Success | `201` Created | `400` Bad Request
- `404` Not Found | `409` Conflict | `500` Server Error

> 📖 **For complete details:** See [docs/API_EXAMPLES.md](docs/API_EXAMPLES.md)

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📈 Version History

- **v1.1.0** (2025-01-10) - Security enhancement with Row Level Security
  - **BREAKING CHANGES**: Basic Authentication required for all endpoints
  - PostgreSQL Row Level Security (RLS) implementation
  - bcrypt password hashing for secure credentials
  - Database-level data isolation per user
  - Enhanced email validation with dot support
  - URL parameter decoding for encoded emails
  - Fixed payload size validation and middleware issues

- **v1.0.0** (2024-09-29) - Initial stable release with full API functionality
  - Complete CRUD operations for users and combinations
  - Euromillions results querying system
  - Comprehensive validation and security
  - Interactive Swagger documentation
  - Production-ready logging system
  - Automated web scraper

> 📋 **Full changelog:** See [CHANGELOG.md](CHANGELOG.md) for detailed release notes.

## 📝 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## 🆘 Support

If you have problems or questions:

1. Check the documentation
2. Search existing issues
3. Create a new issue with problem details

---

**Built with ❤️ using Ruby and Sinatra**
