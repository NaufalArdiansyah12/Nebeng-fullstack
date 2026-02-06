# API Register Documentation

## Endpoint Register

### URL
```
POST /api/v1/auth/register
```

### Headers
```
Content-Type: application/json
Accept: application/json
```

### Request Body
```json
{
  "name": "string (required, max:255)",
  "email": "string (required, email, unique)",
  "password": "string (required, min:8)",
  "password_confirmation": "string (required, same as password)"
}
```

### Success Response (201 Created)
```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "user": {
      "id": 1,
      "name": "Test User",
      "email": "testuser@example.com",
      "role": "customer"
    }
  }
}
```

### Error Response - Validation Failed (422 Unprocessable Entity)
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "email": ["Email sudah terdaftar"],
    "password": ["Password minimal 8 karakter"],
    "password_confirmation": ["Konfirmasi password tidak sama dengan password"]
  }
}
```

### Error Response - Server Error (500 Internal Server Error)
```json
{
  "success": false,
  "message": "Terjadi kesalahan saat registrasi",
  "error": "Error message details"
}
```

## Validation Rules

- **name**: Required, string, maximum 255 characters
- **email**: Required, valid email format, must be unique (not already registered)
- **password**: Required, string, minimum 8 characters
- **password_confirmation**: Required, must match the password field

## Default Values

When a user registers successfully:
- `role`: Set to "customer" by default
- `balance`: Set to 0
- `reward_points`: Set to 0
- `phone_verified`: Set to false

## Example Usage

### cURL Example
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john.doe@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

### Flutter/Dart Example
```dart
final uri = Uri.parse('$API_BASE_URL/api/v1/auth/register');

final response = await http.post(
  uri,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  body: json.encode({
    'name': nameController.text,
    'email': emailController.text,
    'password': passwordController.text,
    'password_confirmation': confirmPasswordController.text,
  }),
);

if (response.statusCode == 201) {
  final data = json.decode(response.body);
  print('Registration successful: ${data['data']['user']}');
} else {
  final error = json.decode(response.body);
  print('Registration failed: ${error['message']}');
}
```

## Notes

1. After successful registration, the user should be redirected to the login page
2. The password is automatically hashed using bcrypt before storing in the database
3. Email uniqueness is enforced at the database level
4. All validation messages are in Bahasa Indonesia for better user experience
5. The API returns appropriate HTTP status codes for different scenarios

## Testing

Run the test script to verify the registration endpoint:
```bash
cd backend/scripts
./test_register.sh
```

This will test:
- Successful registration
- Duplicate email rejection
- Password mismatch validation
- Invalid email format validation
- Short password validation
