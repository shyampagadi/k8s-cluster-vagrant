# Custom Provider Development Mastery - Complete Enterprise Guide

## 🏗️ Provider Architecture Deep Dive

### Terraform Provider Framework
```go
// Provider SDK v2 implementation
package main

import (
    "context"
    "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
    "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
)

// Provider configuration
func Provider() *schema.Provider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "api_url": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "API endpoint URL",
                DefaultFunc: schema.EnvDefaultFunc("CUSTOM_API_URL", nil),
            },
            "api_key": {
                Type:        schema.TypeString,
                Required:    true,
                Sensitive:   true,
                Description: "API authentication key",
                DefaultFunc: schema.EnvDefaultFunc("CUSTOM_API_KEY", nil),
            },
            "timeout": {
                Type:        schema.TypeInt,
                Optional:    true,
                Default:     30,
                Description: "Request timeout in seconds",
            },
        },
        
        ResourcesMap: map[string]*schema.Resource{
            "custom_resource":      resourceCustomResource(),
            "custom_application":   resourceCustomApplication(),
            "custom_database":      resourceCustomDatabase(),
        },
        
        DataSourcesMap: map[string]*schema.Resource{
            "custom_resource":      dataSourceCustomResource(),
            "custom_applications":  dataSourceCustomApplications(),
        },
        
        ConfigureContextFunc: providerConfigure,
    }
}

// Provider configuration function
func providerConfigure(ctx context.Context, d *schema.ResourceData) (interface{}, diag.Diagnostics) {
    apiURL := d.Get("api_url").(string)
    apiKey := d.Get("api_key").(string)
    timeout := d.Get("timeout").(int)
    
    var diags diag.Diagnostics
    
    if apiURL == "" {
        diags = append(diags, diag.Diagnostic{
            Severity: diag.Error,
            Summary:  "API URL is required",
            Detail:   "The API URL must be provided via configuration or environment variable",
        })
        return nil, diags
    }
    
    client := &APIClient{
        BaseURL: apiURL,
        APIKey:  apiKey,
        Timeout: timeout,
    }
    
    // Validate connection
    if err := client.Ping(ctx); err != nil {
        diags = append(diags, diag.Diagnostic{
            Severity: diag.Error,
            Summary:  "Unable to connect to API",
            Detail:   fmt.Sprintf("Connection failed: %s", err.Error()),
        })
        return nil, diags
    }
    
    return client, diags
}
```

### Resource Implementation Patterns
```go
// Resource schema definition
func resourceCustomResource() *schema.Resource {
    return &schema.Resource{
        CreateContext: resourceCustomResourceCreate,
        ReadContext:   resourceCustomResourceRead,
        UpdateContext: resourceCustomResourceUpdate,
        DeleteContext: resourceCustomResourceDelete,
        
        Importer: &schema.ResourceImporter{
            StateContext: schema.ImportStatePassthroughContext,
        },
        
        Schema: map[string]*schema.Schema{
            "name": {
                Type:         schema.TypeString,
                Required:     true,
                ForceNew:     true,
                Description:  "Resource name",
                ValidateFunc: validation.StringLenBetween(1, 64),
            },
            "description": {
                Type:        schema.TypeString,
                Optional:    true,
                Description: "Resource description",
            },
            "tags": {
                Type:        schema.TypeMap,
                Optional:    true,
                Elem:        &schema.Schema{Type: schema.TypeString},
                Description: "Resource tags",
            },
            "configuration": {
                Type:        schema.TypeList,
                Optional:    true,
                MaxItems:    1,
                Description: "Resource configuration",
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{
                        "enabled": {
                            Type:        schema.TypeBool,
                            Optional:    true,
                            Default:     true,
                            Description: "Enable resource",
                        },
                        "settings": {
                            Type:        schema.TypeMap,
                            Optional:    true,
                            Elem:        &schema.Schema{Type: schema.TypeString},
                            Description: "Configuration settings",
                        },
                    },
                },
            },
            "status": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Resource status",
            },
            "created_at": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Creation timestamp",
            },
        },
        
        Timeouts: &schema.ResourceTimeout{
            Create: schema.DefaultTimeout(10 * time.Minute),
            Update: schema.DefaultTimeout(10 * time.Minute),
            Delete: schema.DefaultTimeout(5 * time.Minute),
        },
    }
}

// CRUD operations implementation
func resourceCustomResourceCreate(ctx context.Context, d *schema.ResourceData, meta interface{}) diag.Diagnostics {
    client := meta.(*APIClient)
    
    resource := &CustomResource{
        Name:        d.Get("name").(string),
        Description: d.Get("description").(string),
        Tags:        expandStringMap(d.Get("tags").(map[string]interface{})),
    }
    
    if config, ok := d.GetOk("configuration"); ok {
        resource.Configuration = expandConfiguration(config.([]interface{}))
    }
    
    // Create resource via API
    createdResource, err := client.CreateResource(ctx, resource)
    if err != nil {
        return diag.FromErr(err)
    }
    
    d.SetId(createdResource.ID)
    
    // Wait for resource to be ready
    if err := waitForResourceReady(ctx, client, createdResource.ID, d.Timeout(schema.TimeoutCreate)); err != nil {
        return diag.FromErr(err)
    }
    
    return resourceCustomResourceRead(ctx, d, meta)
}

func resourceCustomResourceRead(ctx context.Context, d *schema.ResourceData, meta interface{}) diag.Diagnostics {
    client := meta.(*APIClient)
    
    resource, err := client.GetResource(ctx, d.Id())
    if err != nil {
        if isNotFoundError(err) {
            d.SetId("")
            return nil
        }
        return diag.FromErr(err)
    }
    
    d.Set("name", resource.Name)
    d.Set("description", resource.Description)
    d.Set("tags", resource.Tags)
    d.Set("status", resource.Status)
    d.Set("created_at", resource.CreatedAt.Format(time.RFC3339))
    
    if resource.Configuration != nil {
        d.Set("configuration", flattenConfiguration(resource.Configuration))
    }
    
    return nil
}
```

## 🔧 Advanced Provider Patterns

### State Management and Drift Detection
```go
// Custom diff function for complex state management
func resourceCustomResourceCustomizeDiff(ctx context.Context, diff *schema.ResourceDiff, meta interface{}) error {
    // Handle computed fields based on configuration changes
    if diff.HasChange("configuration") {
        diff.SetNewComputed("status")
    }
    
    // Validate configuration combinations
    if config := diff.Get("configuration").([]interface{}); len(config) > 0 {
        configMap := config[0].(map[string]interface{})
        if enabled := configMap["enabled"].(bool); !enabled {
            if settings := configMap["settings"].(map[string]interface{}); len(settings) > 0 {
                return fmt.Errorf("settings cannot be specified when resource is disabled")
            }
        }
    }
    
    return nil
}

// State migration for provider upgrades
func resourceCustomResourceStateUpgradeV0(ctx context.Context, rawState map[string]interface{}, meta interface{}) (map[string]interface{}, error) {
    // Migrate from v0 to v1 schema
    if rawState["config"] != nil {
        rawState["configuration"] = []interface{}{rawState["config"]}
        delete(rawState, "config")
    }
    
    return rawState, nil
}
```

### Authentication and Security
```go
// OAuth2 authentication implementation
type OAuth2Config struct {
    ClientID     string
    ClientSecret string
    TokenURL     string
    Scopes       []string
}

func (c *APIClient) authenticateOAuth2(ctx context.Context) error {
    config := &oauth2.Config{
        ClientID:     c.OAuth2.ClientID,
        ClientSecret: c.OAuth2.ClientSecret,
        Endpoint: oauth2.Endpoint{
            TokenURL: c.OAuth2.TokenURL,
        },
        Scopes: c.OAuth2.Scopes,
    }
    
    token, err := config.PasswordCredentialsToken(ctx, c.Username, c.Password)
    if err != nil {
        return fmt.Errorf("OAuth2 authentication failed: %w", err)
    }
    
    c.httpClient = config.Client(ctx, token)
    return nil
}

// API key rotation support
func (c *APIClient) rotateAPIKey(ctx context.Context) error {
    newKey, err := c.generateNewAPIKey(ctx)
    if err != nil {
        return err
    }
    
    // Test new key before switching
    testClient := &APIClient{
        BaseURL: c.BaseURL,
        APIKey:  newKey,
        Timeout: c.Timeout,
    }
    
    if err := testClient.Ping(ctx); err != nil {
        return fmt.Errorf("new API key validation failed: %w", err)
    }
    
    c.APIKey = newKey
    return nil
}
```

### Error Handling and Retry Logic
```go
// Comprehensive error handling
type APIError struct {
    StatusCode int    `json:"status_code"`
    Message    string `json:"message"`
    Details    string `json:"details"`
    RequestID  string `json:"request_id"`
}

func (e *APIError) Error() string {
    return fmt.Sprintf("API Error %d: %s (Request ID: %s)", e.StatusCode, e.Message, e.RequestID)
}

// Retry logic with exponential backoff
func (c *APIClient) makeRequestWithRetry(ctx context.Context, req *http.Request) (*http.Response, error) {
    var lastErr error
    
    for attempt := 0; attempt < c.MaxRetries; attempt++ {
        resp, err := c.httpClient.Do(req.WithContext(ctx))
        if err != nil {
            lastErr = err
            if attempt < c.MaxRetries-1 {
                backoff := time.Duration(math.Pow(2, float64(attempt))) * time.Second
                select {
                case <-time.After(backoff):
                    continue
                case <-ctx.Done():
                    return nil, ctx.Err()
                }
            }
            continue
        }
        
        // Check for retryable status codes
        if resp.StatusCode >= 500 || resp.StatusCode == 429 {
            resp.Body.Close()
            if attempt < c.MaxRetries-1 {
                backoff := time.Duration(math.Pow(2, float64(attempt))) * time.Second
                select {
                case <-time.After(backoff):
                    continue
                case <-ctx.Done():
                    return nil, ctx.Err()
                }
            }
            lastErr = fmt.Errorf("server error: %d", resp.StatusCode)
            continue
        }
        
        return resp, nil
    }
    
    return nil, fmt.Errorf("request failed after %d attempts: %w", c.MaxRetries, lastErr)
}
```

## 🧪 Provider Testing Framework

### Unit Testing
```go
// Unit tests for provider functions
func TestProviderConfigure(t *testing.T) {
    tests := []struct {
        name     string
        config   map[string]interface{}
        wantErr  bool
        errMsg   string
    }{
        {
            name: "valid configuration",
            config: map[string]interface{}{
                "api_url": "https://api.example.com",
                "api_key": "test-key",
                "timeout": 30,
            },
            wantErr: false,
        },
        {
            name: "missing api_url",
            config: map[string]interface{}{
                "api_key": "test-key",
            },
            wantErr: true,
            errMsg:  "API URL is required",
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            d := schema.TestResourceDataRaw(t, Provider().Schema, tt.config)
            
            _, diags := providerConfigure(context.Background(), d)
            
            if tt.wantErr {
                assert.True(t, diags.HasError())
                assert.Contains(t, diags[0].Summary, tt.errMsg)
            } else {
                assert.False(t, diags.HasError())
            }
        })
    }
}
```

### Integration Testing
```go
// Integration tests with real API
func TestResourceCustomResourceCRUD(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    
    resource.Test(t, resource.TestCase{
        PreCheck:          func() { testAccPreCheck(t) },
        ProviderFactories: testAccProviderFactories,
        CheckDestroy:      testAccCheckCustomResourceDestroy,
        Steps: []resource.TestStep{
            {
                Config: testAccCustomResourceConfig("test-resource"),
                Check: resource.ComposeTestCheckFunc(
                    testAccCheckCustomResourceExists("custom_resource.test"),
                    resource.TestCheckResourceAttr("custom_resource.test", "name", "test-resource"),
                    resource.TestCheckResourceAttr("custom_resource.test", "status", "active"),
                ),
            },
            {
                Config: testAccCustomResourceConfigUpdated("test-resource"),
                Check: resource.ComposeTestCheckFunc(
                    testAccCheckCustomResourceExists("custom_resource.test"),
                    resource.TestCheckResourceAttr("custom_resource.test", "description", "updated description"),
                ),
            },
        },
    })
}

func testAccCustomResourceConfig(name string) string {
    return fmt.Sprintf(`
resource "custom_resource" "test" {
  name        = "%s"
  description = "test resource"
  
  configuration {
    enabled = true
    settings = {
      key1 = "value1"
      key2 = "value2"
    }
  }
  
  tags = {
    Environment = "test"
    Purpose     = "integration-test"
  }
}
`, name)
}
```

This comprehensive guide provides enterprise-grade custom provider development patterns with advanced authentication, error handling, testing, and production deployment capabilities.
