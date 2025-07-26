# URL Shortener Service

A Rails API service that provides URL shortening functionality. Users can encode long URLs into short codes and decode short codes back to their original URLs.

## Features

- **URL Encoding**: Convert long URLs into short, shareable links
- **URL Decoding**: Retrieve original URLs from short codes
- **Duplicate Prevention**: Same original URL always returns the same short code
- **Validation**: Ensures URLs are valid and properly formatted
- **RESTful API**: Clean JSON API endpoints
- **Comprehensive Testing**: Full test coverage with RSpec

## Quick Start

To run this application locally, please refer to the detailed setup instructions in [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md).

## Security Considerations

This URL shortener service implements several security measures to protect against common attack vectors:

### Potential Attack Vectors & Mitigations

#### 1. **URL Validation & Sanitization**
- **Attack Vector**: Malicious URLs containing dangerous protocols, fake emails, or redirect chains
- **How it happens**:
  - Attacker submits URLs like `javascript:alert('XSS')` or `data:text/html,<script>alert('XSS')</script>`
  - Fake email URLs like `mailto:fake@bank.com` for phishing
  - Redirect chains: `https://legitimate-site.com/redirect?url=https://evil.com`
  - Phishing URLs like `https://fake-bank.com` that look legitimate
- **Mitigation**: 
  - Strict URL format validation using `URI::regexp(%w[http https])`
  - Only allows HTTP and HTTPS protocols
  - Prevents `javascript:`, `data:`, `mailto:`, and other dangerous protocols
- **Limitations**:
  - Cannot prevent phishing URLs: `https://fake-bank.com` passes validation
  - Cannot detect malicious content on valid domains
  - Cannot prevent redirect chains to malicious destinations

#### 2. **Short Code Enumeration**
- **Attack Vector**: Brute force attempts to guess valid short codes by calling the decode endpoint repeatedly
- **Mitigation**:
  - 6-10 character alphanumeric codes provide 62^6 to 62^10 possible combinations (62 = 26 lowercase + 26 uppercase + 10 digits)
  - 6-character codes: ~56.8 billion combinations
  - 10-character codes: ~839 quadrillion combinations
  - Rate limiting should be implemented in production on the decode endpoint
  - Short codes are randomly generated using `SecureRandom.alphanumeric(6)`

#### 3. **SQL Injection**
- **Attack Vector**: Malicious input attempting to manipulate database queries
- **Mitigation**:
  - Uses ActiveRecord with parameterized queries
  - Input validation and sanitization
  - No raw SQL queries in the application

#### 4. **Cross-Site Scripting (XSS)**
- **Attack Vector**: Malicious scripts injected through URL parameters
- **Mitigation**:
  - JSON API responses with proper content-type headers
  - No user-generated HTML rendering
  - Input validation prevents script injection

#### 5. **Denial of Service (DoS)**
- **Attack Vector**: Flooding the service with requests or creating excessive short URLs
- **Mitigation**:
  - Duplicate URL prevention reduces database bloat
  - Rate limiting should be implemented in production
  - Database indexes on `original_url` and `short_code` for performance

#### 6. **Short Code Collision Attacks**
- **Attack Vector**: Attempting to create collisions in short code generation
- **Mitigation**:
  - Collision detection in `generate_short_code` method
  - Loop continues until unique code is generated
  - Database uniqueness constraint as backup

### Security Best Practices Implemented

1. **Input Validation**: All URLs are validated for format and protocol
2. **Output Encoding**: JSON responses are properly encoded
3. **Error Handling**: Generic error messages prevent information disclosure
4. **Database Security**: Parameterized queries prevent SQL injection
5. **Random Generation**: Secure random number generation for short codes

### Recommended Production Security Measures

1. **Rate Limiting**: Implement request rate limiting per IP
2. **HTTPS**: Use HTTPS in production for all communications
4. **Logging**: Implement security event logging and monitoring
6. **API Authentication**: Consider implementing API keys for production use
7. **Database Security**: Use connection pooling and prepared statements
8. **Monitoring**: Set up alerts for unusual traffic patterns
