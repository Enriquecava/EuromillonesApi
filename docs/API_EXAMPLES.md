# API Usage Examples

This guide contains practical examples of how to use all endpoints of the EuromillonesApi.

## 🔧 Initial Setup

### Using curl
```bash
# API base URL
BASE_URL="http://localhost:4567"
```

### Using JavaScript/Node.js
```javascript
const BASE_URL = 'http://localhost:4567';

const apiCall = async (endpoint, method = 'GET', body = null) => {
  const options = {
    method,
    headers: { 'Content-Type': 'application/json' }
  };
  
  if (body) options.body = JSON.stringify(body);
  
  const response = await fetch(`${BASE_URL}${endpoint}`, options);
  return response.json();
};
```

## 📋 Examples by Endpoint

### 1. API Information

```bash
curl -X GET http://localhost:4567/
```

**Response:**
```json
{
  "api": "Euromillones Results API",
  "version": "1.0",
  "endpoints": { ... },
  "description": "This API allows you to query Euromillones results, manage users and their combinations."
}
```

### 2. Health Check

```bash
curl -X GET http://localhost:4567/health
```

**Success response:**
```json
{
  "status": "OK",
  "message": "API is live and database is reachable"
}
```

## 🎲 Results Management

### Query result by date

```bash
curl -X GET http://localhost:4567/results/2024-01-15
```

**Success response:**
```json
{
  "date": "2024-01-15",
  "balls": [7, 23, 34, 42, 48],
  "stars": [3, 8],
  "jackpot": {
    "5": {
      "2": "15000000.00",
      "1": "250000.00",
      "0": "50000.00"
    },
    "4": {
      "2": "5000.00",
      "1": "500.00",
      "0": "100.00"
    }
  }
}
```

**Error - Invalid date:**
```bash
curl -X GET http://localhost:4567/results/2024-13-45
```
```json
{
  "error": "Invalid date format (use YYYY-MM-DD)"
}
```

**Error - Future date:**
```bash
curl -X GET http://localhost:4567/results/2025-12-31
```
```json
{
  "error": "Date cannot be in the future"
}
```

## 👥 User Management

### Create user

```bash
curl -X POST http://localhost:4567/user \
  -H "Content-Type: application/json" \
  -d '{"email": "john@example.com"}'
```

**Success response (201):**
```json
{
  "message": "User created",
  "email": "john@example.com"
}
```

**Error - Invalid email:**
```bash
curl -X POST http://localhost:4567/user \
  -H "Content-Type: application/json" \
  -d '{"email": "invalid-email"}'
```
```json
{
  "error": "Invalid email format"
}
```

**Error - Email already exists:**
```json
{
  "error": "Email already exists"
}
```

### Get user

```bash
curl -X GET http://localhost:4567/user/john@example.com
```

**Success response:**
```json
{
  "email": "john@example.com",
  "user_id": "123"
}
```

### Update user email

```bash
curl -X PUT http://localhost:4567/user/john@example.com \
  -H "Content-Type: application/json" \
  -d '{"email": "john.new@example.com"}'
```

**Success response:**
```json
{
  "message": "User email updated",
  "old_email": "john@example.com",
  "new_email": "john.new@example.com"
}
```

### Delete user

```bash
curl -X DELETE http://localhost:4567/user/john.new@example.com
```

**Success response:**
```json
{
  "message": "User deleted",
  "email": "john.new@example.com"
}
```

## 🎯 Combination Management

### Create combination

```bash
curl -X POST http://localhost:4567/combinations \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "balls": [7, 15, 23, 34, 42],
    "stars": [3, 8]
  }'
```

**Success response (201):**
```json
{
  "message": "Combination succesfully added",
  "email": "john@example.com",
  "balls": [7, 15, 23, 34, 42],
  "stars": [3, 8],
  "combination_id": "456"
}
```

**Error - Invalid balls:**
```bash
curl -X POST http://localhost:4567/combinations \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "balls": [7, 15, 23],
    "stars": [3, 8]
  }'
```
```json
{
  "error": "At least 5 balls required"
}
```

**Error - Invalid ball range:**
```bash
curl -X POST http://localhost:4567/combinations \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "balls": [7, 15, 23, 34, 55],
    "stars": [3, 8]
  }'
```
```json
{
  "error": "Balls must be between 1 and 50"
}
```

**Error - Duplicate balls:**
```bash
curl -X POST http://localhost:4567/combinations \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "balls": [7, 7, 23, 34, 42],
    "stars": [3, 8]
  }'
```
```json
{
  "error": "Duplicate balls are not allowed"
}
```

### Get user combinations

```bash
curl -X GET http://localhost:4567/combinations/john@example.com
```

**Success response:**
```json
{
  "email": "john@example.com",
  "combinations": [
    {
      "id": 456,
      "balls": [7, 15, 23, 34, 42],
      "stars": [3, 8]
    },
    {
      "id": 457,
      "balls": [1, 12, 25, 38, 49],
      "stars": [2, 11]
    }
  ]
}
```

### Update combination

```bash
curl -X PUT http://localhost:4567/combinations/456 \
  -H "Content-Type: application/json" \
  -d '{
    "balls": [5, 18, 27, 36, 45],
    "stars": [4, 9]
  }'
```

**Success response:**
```json
{
  "message": "Combination updated",
  "id": 456,
  "balls": [5, 18, 27, 36, 45],
  "stars": [4, 9]
}
```

### Delete combination

```bash
curl -X DELETE http://localhost:4567/combinations/456
```

**Success response:**
```json
{
  "message": "Combination deleted",
  "id": 456
}
```

## 🔄 Complete Workflows

### Workflow: New user with combinations

```bash
# 1. Create user
curl -X POST http://localhost:4567/user \
  -H "Content-Type: application/json" \
  -d '{"email": "maria@example.com"}'

# 2. Add first combination
curl -X POST http://localhost:4567/combinations \
  -H "Content-Type: application/json" \
  -d '{
    "email": "maria@example.com",
    "balls": [3, 17, 28, 41, 50],
    "stars": [1, 12]
  }'

# 3. Add second combination
curl -X POST http://localhost:4567/combinations \
  -H "Content-Type: application/json" \
  -d '{
    "email": "maria@example.com",
    "balls": [9, 21, 33, 44, 47],
    "stars": [5, 7]
  }'

# 4. Get all combinations
curl -X GET http://localhost:4567/combinations/maria@example.com
```

### Workflow: Query historical results

```bash
# Query multiple results
curl -X GET http://localhost:4567/results/2024-01-12
curl -X GET http://localhost:4567/results/2024-01-09
curl -X GET http://localhost:4567/results/2024-01-05
```

## 🐍 Python Example

```python
import requests
import json

class EuromillonesAPI:
    def __init__(self, base_url="http://localhost:4567"):
        self.base_url = base_url
    
    def create_user(self, email):
        response = requests.post(
            f"{self.base_url}/user",
            json={"email": email}
        )
        return response.json()
    
    def add_combination(self, email, balls, stars):
        response = requests.post(
            f"{self.base_url}/combinations",
            json={
                "email": email,
                "balls": balls,
                "stars": stars
            }
        )
        return response.json()
    
    def get_result(self, date):
        response = requests.get(f"{self.base_url}/results/{date}")
        return response.json()

# Usage
api = EuromillonesAPI()

# Create user
user = api.create_user("python@example.com")
print(user)

# Add combination
combination = api.add_combination(
    "python@example.com",
    [10, 20, 30, 40, 50],
    [6, 10]
)
print(combination)

# Query result
result = api.get_result("2024-01-15")
print(result)
```

## 🟢 HTTP Status Codes

| Code | Meaning | When it occurs |
|------|---------|----------------|
| 200 | OK | Successful operation |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid or missing data |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists |
| 500 | Internal Server Error | Server error |

## 🚨 Error Handling

### Error response structure
```json
{
  "error": "Error description",
  "details": "Additional information (optional)"
}
```

### Common errors and solutions

**Invalid email:**
```json
{
  "error": "Invalid email format"
}
```
*Solution: Include valid email in the request body*

**Duplicate combination:**
```json
{
  "error": "Combination already exists for this user"
}
```
*Solution: Use different combination or update existing one*

**User not found:**
```json
{
  "error": "User not found"
}
```
*Solution: Verify that the user email exists*

**Invalid balls range:**
```json
{
  "error": "Balls must be between 1 and 50"
}
```
*Solution: Use numbers within valid range (1-50)*

**Invalid stars range:**
```json
{
  "error": "Stars must be between 1 and 12"
}
```
*Solution: Use numbers within valid range (1-12)*

## 📊 Usage Tips

1. **Validate dates**: Use YYYY-MM-DD format
2. **Unique emails**: Each email can only have one user
3. **Valid combinations**: 5 balls (1-50) and 2 stars (1-12)
4. **No duplicates**: Within balls or stars arrays
5. **Rate limiting**: Avoid too many simultaneous requests
6. **Error handling**: Always check HTTP status codes

## 🔍 Validation Rules

### Email Validation
- Must be a valid email format
- Must be unique in the system
- Cannot be empty or null

### Combination Validation
- **Balls**: Exactly 5 numbers, range 1-50, no duplicates
- **Stars**: Exactly 2 numbers, range 1-12, no duplicates
- All numbers must be integers

### Date Validation
- Format: YYYY-MM-DD
- Cannot be in the future
- Must be a valid calendar date

---

For more information, check the [main README](../README.md).