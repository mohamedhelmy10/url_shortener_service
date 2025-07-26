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

## Scaling Considerations

This URL shortener service is designed with scalability in mind. Here's how the implementation can scale up to handle high traffic and large datasets:

### Collision Problem & Solutions

#### **Current Implementation**
```ruby
def generate_short_code
  loop do
    code = SecureRandom.alphanumeric(6)
    return code unless ShortUrl.exists?(short_code: code)
  end
end
```

#### **Scaling Challenges**
1. **Database Lookups**: Each collision check requires a database query
2. **Performance Degradation**: More collisions = more database hits
3. **Concurrency Issues**: Multiple requests might generate same code simultaneously

#### **Scaling Solutions**

##### **1. Pre-generated Code Pools**
```ruby
# Generate codes in batches with duplicate prevention
class ShortCodePool
  def self.generate_batch(size = 1000)
    codes = Set.new
    
    # Keep generating until we have enough unique codes
    while codes.size < size
      new_code = SecureRandom.alphanumeric(6)
      codes.add(new_code) unless ShortUrl.exists?(short_code: new_code)
    end
    
    # Bulk insert available codes
    ShortCodePool.create(codes.map { |code| { code: code, used: false } })
  end
  
  def self.get_available_code
    # Try to get an available code
    pool = ShortCodePool.where(used: false).first
    
    if pool
      pool.update(used: true)
      return pool.code
    else
      # No codes available, generate new batch
      Rails.logger.info "ShortCodePool empty, generating new batch..."
      generate_batch(1000)
      
      # Try again after generating new batch
      pool = ShortCodePool.where(used: false).first
      if pool
        pool.update(used: true)
        return pool.code
      else
        # Still no codes available (shouldn't happen, but safety check)
        Rails.logger.error "Failed to generate new ShortCodePool batch"
        return nil
      end
    end
  end
  
  # Usage with validation
  def self.get_available_code_safe
    code = get_available_code
    if code.nil?
      raise "Unable to generate short code - pool generation failed"
    end
    code
  end
```

##### **2. Increased Code Length**
```ruby
# Scale from 6 to 8 characters for more combinations
def generate_short_code
  SecureRandom.alphanumeric(8)  # 62^8 = ~218 trillion combinations
end
```

##### **3. Distributed Generation**
```ruby
# Use unique identifiers to prevent collisions
def generate_short_code
  timestamp = Time.current.to_i
  random_part = SecureRandom.alphanumeric(4)
  "#{timestamp}#{random_part}"
end
```

##### **4. Database Optimization**
```ruby
# Add database indexes for performance
add_index :short_urls, :short_code, unique: true
add_index :short_urls, :original_url
add_index :short_urls, :created_at

# Use database-level uniqueness constraints
validates :short_code, uniqueness: true
```

### **High Traffic Scaling**

#### **1. Caching Strategy**
```ruby
# Redis caching for frequently accessed URLs
class ShortUrl < ApplicationRecord
  def self.find_by_short_code_cached(code)
    Rails.cache.fetch("short_url:#{code}", expires_in: 1.hour) do
      find_by(short_code: code)
    end
  end
end
```

#### **2. Database Sharding**
```ruby
# Shard by short_code prefix
class ShortUrl < ApplicationRecord
  def self.shard_for_code(code)
    shard_id = code.first.ord % 10  # Distribute across 10 shards
    "shard_#{shard_id}"
  end
end
```

### **Recommended Scaling Roadmap**

#### **Phase 1: Immediate (Current)**
- ✅ Current implementation with collision detection
- ✅ Database indexes
- ✅ Basic error handling

#### **Phase 2: Medium Scale (10K-100K URLs/day)**
- Add Redis caching
- Implement pre-generated code pools
- Add monitoring and alerting

#### **Phase 3: High Scale (1M+ URLs/day)**
- Database sharding

#### **Phase 4: Enterprise Scale (10M+ URLs/day)**
- Global distribution
- Advanced caching strategies


This scaling approach ensures the service can grow from handling hundreds of requests per day to millions, while maintaining performance and reliability.

## API Endpoints
