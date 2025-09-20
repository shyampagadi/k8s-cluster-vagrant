# Custom Providers Troubleshooting Guide

## 🚨 Common Issues and Solutions

This guide covers troubleshooting techniques for Terraform custom provider development, authentication issues, resource management problems, and integration challenges.

## 📋 Table of Contents

1. [Provider Development Issues](#provider-development-issues)
2. [Authentication and Configuration Problems](#authentication-and-configuration-problems)
3. [Resource Management Challenges](#resource-management-challenges)
4. [Data Source Implementation Issues](#data-source-implementation-issues)
5. [Provider Testing and Validation Problems](#provider-testing-and-validation-problems)
6. [Performance and Optimization Issues](#performance-and-optimization-issues)
7. [Integration and Deployment Challenges](#integration-and-deployment-challenges)
8. [Advanced Debugging Techniques](#advanced-debugging-techniques)

---

## 🔧 Provider Development Issues

### Problem: Provider Compilation Failures

**Symptoms:**
```
Error: failed to build provider: exit status 1
```

**Root Causes:**
- Go version incompatibility
- Missing dependencies
- Syntax errors in provider code
- Import path issues

**Solutions:**

#### Solution 1: Verify Go Environment
```bash
# ✅ Check Go version and environment
go version
go env GOPATH
go env GOROOT

# ✅ Ensure Go 1.19+ is installed
go version | grep -E "go1\.(19|2[0-9])"
```

#### Solution 2: Fix Dependencies
```bash
# ✅ Clean and rebuild dependencies
go mod tidy
go mod download
go mod verify

# ✅ Update dependencies
go get -u github.com/hashicorp/terraform-plugin-sdk/v2
go mod tidy
```

#### Solution 3: Provider Code Validation
```go
// ✅ Ensure proper provider structure
package main

import (
    "context"
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
    "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
)

func main() {
    plugin.Serve(&plugin.ServeOpts{
        ProviderFunc: Provider,
    })
}

func Provider() *schema.Provider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "api_key": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "API key for authentication",
            },
        },
        ResourcesMap: map[string]*schema.Resource{
            "custom_api_resource": resourceCustomAPIResource(),
        },
        DataSourcesMap: map[string]*schema.Resource{
            "custom_api_data": dataSourceCustomAPIData(),
        },
    }
}
```

### Problem: Provider Schema Validation Errors

**Symptoms:**
```
Error: Invalid provider configuration: missing required argument "api_key"
```

**Root Causes:**
- Missing required provider arguments
- Incorrect schema definitions
- Validation rule failures

**Solutions:**

#### Solution 1: Fix Provider Schema
```go
// ✅ Proper provider schema definition
func Provider() *schema.Provider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "api_key": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "API key for authentication",
                Sensitive:   true,
            },
            "base_url": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "Base URL for API requests",
                DefaultFunc: schema.EnvDefaultFunc("CUSTOM_API_URL", "https://api.example.com"),
            },
            "timeout": {
                Type:        schema.TypeInt,
                Optional:    true,
                Description: "Request timeout in seconds",
                Default:     30,
            },
        },
        // ... rest of provider configuration
    }
}
```

#### Solution 2: Add Provider Validation
```go
// ✅ Add provider validation
func Provider() *schema.Provider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "api_key": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "API key for authentication",
                ValidateFunc: func(v interface{}, k string) (warns []string, errs []error) {
                    apiKey := v.(string)
                    if len(apiKey) < 10 {
                        errs = append(errs, fmt.Errorf("API key must be at least 10 characters long"))
                    }
                    return warns, errs
                },
            },
        },
        // ... rest of provider configuration
    }
}
```

---

## 🔐 Authentication and Configuration Problems

### Problem: Authentication Failures

**Symptoms:**
```
Error: authentication failed: invalid API key
```

**Root Causes:**
- Invalid API credentials
- Expired authentication tokens
- Incorrect authentication method
- Network connectivity issues

**Solutions:**

#### Solution 1: Implement Robust Authentication
```go
// ✅ Robust authentication implementation
func (c *APIClient) authenticate(ctx context.Context) error {
    // Try multiple authentication methods
    if c.apiKey != "" {
        return c.authenticateWithAPIKey(ctx)
    }
    
    if c.username != "" && c.password != "" {
        return c.authenticateWithCredentials(ctx)
    }
    
    if c.token != "" {
        return c.authenticateWithToken(ctx)
    }
    
    return fmt.Errorf("no valid authentication method provided")
}

func (c *APIClient) authenticateWithAPIKey(ctx context.Context) error {
    req, err := http.NewRequestWithContext(ctx, "GET", c.baseURL+"/auth/validate", nil)
    if err != nil {
        return err
    }
    
    req.Header.Set("Authorization", "Bearer "+c.apiKey)
    req.Header.Set("Content-Type", "application/json")
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != 200 {
        return fmt.Errorf("authentication failed with status %d", resp.StatusCode)
    }
    
    return nil
}
```

#### Solution 2: Add Authentication Retry Logic
```go
// ✅ Authentication with retry logic
func (c *APIClient) authenticateWithRetry(ctx context.Context, maxRetries int) error {
    for i := 0; i < maxRetries; i++ {
        err := c.authenticate(ctx)
        if err == nil {
            return nil
        }
        
        if i < maxRetries-1 {
            time.Sleep(time.Duration(i+1) * time.Second)
        }
    }
    
    return fmt.Errorf("authentication failed after %d retries", maxRetries)
}
```

### Problem: Configuration Validation Failures

**Symptoms:**
```
Error: provider configuration validation failed: invalid base URL
```

**Root Causes:**
- Invalid URL format
- Missing required configuration
- Incorrect configuration values

**Solutions:**

#### Solution 1: Comprehensive Configuration Validation
```go
// ✅ Comprehensive configuration validation
func Provider() *schema.Provider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "base_url": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "Base URL for API requests",
                ValidateFunc: func(v interface{}, k string) (warns []string, errs []error) {
                    url := v.(string)
                    if _, err := url.Parse(url); err != nil {
                        errs = append(errs, fmt.Errorf("invalid URL format: %s", err))
                    }
                    if !strings.HasPrefix(url, "https://") {
                        warns = append(warns, "using HTTP instead of HTTPS is not recommended")
                    }
                    return warns, errs
                },
            },
            "timeout": {
                Type:        schema.TypeInt,
                Optional:    true,
                Description: "Request timeout in seconds",
                Default:     30,
                ValidateFunc: func(v interface{}, k string) (warns []string, errs []error) {
                    timeout := v.(int)
                    if timeout < 1 || timeout > 300 {
                        errs = append(errs, fmt.Errorf("timeout must be between 1 and 300 seconds"))
                    }
                    return warns, errs
                },
            },
        },
        // ... rest of provider configuration
    }
}
```

---

## 📦 Resource Management Challenges

### Problem: Resource Creation Failures

**Symptoms:**
```
Error: failed to create resource: API request failed with status 400
```

**Root Causes:**
- Invalid resource data
- API endpoint issues
- Missing required fields
- Resource conflicts

**Solutions:**

#### Solution 1: Robust Resource Creation
```go
// ✅ Robust resource creation with validation
func resourceCustomAPIResourceCreate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    // Validate resource data
    if err := validateResourceData(d); err != nil {
        return diag.FromErr(err)
    }
    
    // Prepare resource data
    resourceData := map[string]interface{}{
        "name":        d.Get("name").(string),
        "description": d.Get("description").(string),
        "enabled":     d.Get("enabled").(bool),
    }
    
    // Create resource with retry logic
    var resourceID string
    err := retryOperation(func() error {
        id, err := client.CreateResource(ctx, resourceData)
        if err != nil {
            return err
        }
        resourceID = id
        return nil
    }, 3)
    
    if err != nil {
        return diag.FromErr(err)
    }
    
    d.SetId(resourceID)
    return resourceCustomAPIResourceRead(ctx, d, m)
}

func validateResourceData(d *schema.ResourceData) error {
    name := d.Get("name").(string)
    if len(name) < 3 {
        return fmt.Errorf("resource name must be at least 3 characters long")
    }
    
    description := d.Get("description").(string)
    if len(description) > 1000 {
        return fmt.Errorf("description must be less than 1000 characters")
    }
    
    return nil
}
```

#### Solution 2: Resource Conflict Resolution
```go
// ✅ Handle resource conflicts
func resourceCustomAPIResourceCreate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    // Check for existing resource
    existingResource, err := client.GetResourceByName(ctx, d.Get("name").(string))
    if err == nil && existingResource != nil {
        // Resource exists, handle conflict
        if d.Get("force_create").(bool) {
            // Delete existing resource
            if err := client.DeleteResource(ctx, existingResource.ID); err != nil {
                return diag.FromErr(fmt.Errorf("failed to delete existing resource: %s", err))
            }
        } else {
            return diag.FromErr(fmt.Errorf("resource with name '%s' already exists", d.Get("name").(string)))
        }
    }
    
    // Create new resource
    return createResource(ctx, d, m)
}
```

### Problem: Resource Update Failures

**Symptoms:**
```
Error: failed to update resource: resource not found
```

**Root Causes:**
- Resource deleted outside Terraform
- Incorrect resource ID
- API endpoint changes
- Network connectivity issues

**Solutions:**

#### Solution 1: Robust Resource Updates
```go
// ✅ Robust resource update with validation
func resourceCustomAPIResourceUpdate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    // Check if resource exists
    resource, err := client.GetResource(ctx, d.Id())
    if err != nil {
        if isNotFoundError(err) {
            // Resource not found, create it
            return resourceCustomAPIResourceCreate(ctx, d, m)
        }
        return diag.FromErr(err)
    }
    
    // Prepare update data
    updateData := map[string]interface{}{}
    
    if d.HasChange("name") {
        updateData["name"] = d.Get("name").(string)
    }
    
    if d.HasChange("description") {
        updateData["description"] = d.Get("description").(string)
    }
    
    if d.HasChange("enabled") {
        updateData["enabled"] = d.Get("enabled").(bool)
    }
    
    // Update resource
    err = client.UpdateResource(ctx, d.Id(), updateData)
    if err != nil {
        return diag.FromErr(err)
    }
    
    return resourceCustomAPIResourceRead(ctx, d, m)
}
```

---

## 📊 Data Source Implementation Issues

### Problem: Data Source Query Failures

**Symptoms:**
```
Error: failed to query data source: API request failed with status 404
```

**Root Causes:**
- Invalid query parameters
- API endpoint changes
- Authentication issues
- Network connectivity problems

**Solutions:**

#### Solution 1: Robust Data Source Implementation
```go
// ✅ Robust data source implementation
func dataSourceCustomAPIDataRead(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    // Build query parameters
    queryParams := map[string]string{}
    
    if name, ok := d.GetOk("name"); ok {
        queryParams["name"] = name.(string)
    }
    
    if status, ok := d.GetOk("status"); ok {
        queryParams["status"] = status.(string)
    }
    
    // Query data with retry logic
    var data []map[string]interface{}
    err := retryOperation(func() error {
        result, err := client.QueryData(ctx, queryParams)
        if err != nil {
            return err
        }
        data = result
        return nil
    }, 3)
    
    if err != nil {
        return diag.FromErr(err)
    }
    
    // Process and set data
    if len(data) == 0 {
        return diag.Errorf("no data found matching criteria")
    }
    
    // Set the first result as the data source result
    result := data[0]
    d.SetId(result["id"].(string))
    d.Set("name", result["name"])
    d.Set("description", result["description"])
    d.Set("status", result["status"])
    
    return nil
}
```

#### Solution 2: Data Source Filtering and Validation
```go
// ✅ Data source with filtering and validation
func dataSourceCustomAPIDataRead(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    // Validate input parameters
    if err := validateDataSourceInput(d); err != nil {
        return diag.FromErr(err)
    }
    
    // Query data
    data, err := client.QueryData(ctx, buildQueryParams(d))
    if err != nil {
        return diag.FromErr(err)
    }
    
    // Filter results
    filteredData := filterData(data, d)
    
    if len(filteredData) == 0 {
        return diag.Errorf("no data found matching criteria")
    }
    
    // Set result
    result := filteredData[0]
    d.SetId(result["id"].(string))
    setDataSourceResult(d, result)
    
    return nil
}

func validateDataSourceInput(d *schema.ResourceData) error {
    name := d.Get("name").(string)
    if name != "" && len(name) < 3 {
        return fmt.Errorf("name filter must be at least 3 characters long")
    }
    
    return nil
}

func filterData(data []map[string]interface{}, d *schema.ResourceData) []map[string]interface{} {
    var filtered []map[string]interface{}
    
    for _, item := range data {
        if matchesFilters(item, d) {
            filtered = append(filtered, item)
        }
    }
    
    return filtered
}
```

---

## 🧪 Provider Testing and Validation Problems

### Problem: Provider Test Failures

**Symptoms:**
```
Error: provider test failed: resource creation test failed
```

**Root Causes:**
- Invalid test configuration
- Missing test dependencies
- API endpoint issues
- Test data conflicts

**Solutions:**

#### Solution 1: Comprehensive Provider Testing
```go
// ✅ Comprehensive provider testing
func TestProvider(t *testing.T) {
    if err := Provider().InternalValidate(); err != nil {
        t.Fatalf("err: %s", err)
    }
}

func TestProviderSchema(t *testing.T) {
    provider := Provider()
    
    // Test required fields
    requiredFields := []string{"api_key", "base_url"}
    for _, field := range requiredFields {
        if _, ok := provider.Schema[field]; !ok {
            t.Errorf("required field %s not found in schema", field)
        }
    }
}

func TestResourceCustomAPIResource(t *testing.T) {
    resource := resourceCustomAPIResource()
    
    if resource == nil {
        t.Fatal("resource is nil")
    }
    
    if resource.Create == nil {
        t.Fatal("resource Create function is nil")
    }
    
    if resource.Read == nil {
        t.Fatal("resource Read function is nil")
    }
    
    if resource.Update == nil {
        t.Fatal("resource Update function is nil")
    }
    
    if resource.Delete == nil {
        t.Fatal("resource Delete function is nil")
    }
}
```

#### Solution 2: Integration Testing
```go
// ✅ Integration testing with real API
func TestResourceCustomAPIResourceIntegration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    
    // Setup test environment
    client := setupTestClient(t)
    
    // Test resource creation
    resourceData := map[string]interface{}{
        "name":        "test-resource",
        "description": "test description",
        "enabled":     true,
    }
    
    resourceID, err := client.CreateResource(context.Background(), resourceData)
    if err != nil {
        t.Fatalf("failed to create resource: %s", err)
    }
    
    // Test resource reading
    resource, err := client.GetResource(context.Background(), resourceID)
    if err != nil {
        t.Fatalf("failed to read resource: %s", err)
    }
    
    if resource["name"] != "test-resource" {
        t.Errorf("expected name 'test-resource', got '%s'", resource["name"])
    }
    
    // Cleanup
    if err := client.DeleteResource(context.Background(), resourceID); err != nil {
        t.Errorf("failed to cleanup resource: %s", err)
    }
}
```

---

## ⚡ Performance and Optimization Issues

### Problem: Slow Provider Operations

**Symptoms:**
- Resource operations taking > 30 seconds
- High API usage
- Provider timeouts

**Root Causes:**
- Inefficient API calls
- Missing caching
- Network latency
- Large data processing

**Solutions:**

#### Solution 1: Implement Caching
```go
// ✅ Implement provider caching
type CachedAPIClient struct {
    client *APIClient
    cache  map[string]interface{}
    mutex  sync.RWMutex
}

func (c *CachedAPIClient) GetResource(ctx context.Context, id string) (map[string]interface{}, error) {
    // Check cache first
    c.mutex.RLock()
    if cached, ok := c.cache[id]; ok {
        c.mutex.RUnlock()
        return cached.(map[string]interface{}), nil
    }
    c.mutex.RUnlock()
    
    // Fetch from API
    resource, err := c.client.GetResource(ctx, id)
    if err != nil {
        return nil, err
    }
    
    // Cache result
    c.mutex.Lock()
    c.cache[id] = resource
    c.mutex.Unlock()
    
    return resource, nil
}
```

#### Solution 2: Optimize API Calls
```go
// ✅ Optimize API calls with batching
func (c *APIClient) GetResourcesBatch(ctx context.Context, ids []string) ([]map[string]interface{}, error) {
    // Batch API calls to reduce network overhead
    batchSize := 10
    var results []map[string]interface{}
    
    for i := 0; i < len(ids); i += batchSize {
        end := i + batchSize
        if end > len(ids) {
            end = len(ids)
        }
        
        batch := ids[i:end]
        batchResults, err := c.getResourceBatch(ctx, batch)
        if err != nil {
            return nil, err
        }
        
        results = append(results, batchResults...)
    }
    
    return results, nil
}
```

---

## 🔧 Advanced Debugging Techniques

### Technique 1: Provider Debug Logging
```go
// ✅ Add comprehensive debug logging
func (c *APIClient) makeRequest(ctx context.Context, method, endpoint string, data interface{}) (*http.Response, error) {
    // Log request details
    log.Printf("[DEBUG] Making %s request to %s", method, endpoint)
    
    req, err := http.NewRequestWithContext(ctx, method, c.baseURL+endpoint, nil)
    if err != nil {
        log.Printf("[ERROR] Failed to create request: %s", err)
        return nil, err
    }
    
    // Add authentication
    req.Header.Set("Authorization", "Bearer "+c.apiKey)
    req.Header.Set("Content-Type", "application/json")
    
    // Log request headers
    log.Printf("[DEBUG] Request headers: %v", req.Header)
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        log.Printf("[ERROR] Request failed: %s", err)
        return nil, err
    }
    
    // Log response details
    log.Printf("[DEBUG] Response status: %d", resp.StatusCode)
    log.Printf("[DEBUG] Response headers: %v", resp.Header)
    
    return resp, nil
}
```

### Technique 2: Provider State Inspection
```go
// ✅ Add state inspection capabilities
func (c *APIClient) InspectState(ctx context.Context) map[string]interface{} {
    return map[string]interface{}{
        "base_url":    c.baseURL,
        "timeout":     c.timeout,
        "api_key_set": c.apiKey != "",
        "cache_size":  len(c.cache),
    }
}
```

### Technique 3: Provider Health Checks
```go
// ✅ Implement provider health checks
func (c *APIClient) HealthCheck(ctx context.Context) error {
    req, err := http.NewRequestWithContext(ctx, "GET", c.baseURL+"/health", nil)
    if err != nil {
        return err
    }
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != 200 {
        return fmt.Errorf("health check failed with status %d", resp.StatusCode)
    }
    
    return nil
}
```

---

## 🛡️ Prevention Strategies

### Strategy 1: Provider Testing Pipeline
```yaml
# ✅ CI/CD pipeline for provider testing
name: Provider Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Go
        uses: actions/setup-go@v2
        with:
          go-version: 1.19
          
      - name: Run Tests
        run: |
          go test ./...
          go test -race ./...
          
      - name: Build Provider
        run: go build -o terraform-provider-custom
```

### Strategy 2: Provider Documentation
```markdown
# ✅ Comprehensive provider documentation
## Custom API Provider

### Purpose
Manages resources in the Custom API service.

### Configuration
```hcl
provider "custom_api" {
  api_key  = "your-api-key"
  base_url = "https://api.example.com"
  timeout  = 30
}
```

### Resources
- `custom_api_resource`: Manages API resources

### Data Sources
- `custom_api_data`: Queries API data

### Examples
[Include usage examples]
```

### Strategy 3: Provider Monitoring
```go
// ✅ Add provider monitoring
func (c *APIClient) GetMetrics() map[string]interface{} {
    return map[string]interface{}{
        "requests_total":    c.requestCount,
        "requests_failed":   c.failedRequestCount,
        "cache_hits":       c.cacheHits,
        "cache_misses":     c.cacheMisses,
        "average_latency":  c.averageLatency,
    }
}
```

---

## 📞 Getting Help

### Internal Resources
- Review provider documentation
- Check team knowledge base
- Consult with senior team members

### External Resources
- [Terraform Provider Development](https://www.terraform.io/docs/plugin/sdkv2/index.html)
- [Terraform Plugin SDK](https://github.com/hashicorp/terraform-plugin-sdk)
- [Go Documentation](https://golang.org/doc/)

### Escalation Process
1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review provider documentation
3. **Level 3**: Consult with team members
4. **Level 4**: Escalate to senior architects
5. **Level 5**: Contact HashiCorp support (if applicable)

---

## 🎯 Key Takeaways

- **Test Thoroughly**: Implement comprehensive testing
- **Handle Errors**: Implement robust error handling
- **Monitor Performance**: Track provider performance
- **Document Everything**: Maintain clear documentation
- **Validate Input**: Always validate provider input
- **Cache Appropriately**: Implement caching for performance
- **Log Comprehensively**: Add detailed logging
- **Plan for Failures**: Implement retry and fallback logic

Remember: Custom provider development requires careful planning, thorough testing, and robust error handling. Proper implementation ensures reliable and efficient infrastructure management.
