# Custom Terraform Providers - Development Guide

## Overview
This guide covers custom Terraform provider development, including provider architecture, development workflow, testing strategies, and integration patterns.

## Custom Provider Fundamentals

### What are Custom Providers?
Custom Terraform providers are plugins that extend Terraform's capabilities to manage resources in systems that don't have official providers. They enable:
- **System Integration**: Integrate with custom or legacy systems
- **API Wrappers**: Create wrappers around existing APIs
- **Domain-Specific Resources**: Manage domain-specific resources
- **Legacy System Support**: Support for legacy or proprietary systems

### Provider Architecture
```
custom-provider/
├── main.go              # Provider entry point
├── provider.go          # Provider configuration
├── resources/           # Resource implementations
│   ├── resource_example.go
│   └── resource_another.go
├── data_sources/        # Data source implementations
│   ├── data_source_example.go
│   └── data_source_another.go
├── go.mod              # Go module definition
├── go.sum              # Go module checksums
└── README.md           # Provider documentation
```

## Provider Development Workflow

### Initial Setup
```go
// main.go - Provider entry point
package main

import (
    "context"
    "flag"
    "log"

    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
    "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
)

func main() {
    var debugMode bool

    flag.BoolVar(&debugMode, "debug", false, "set to true to run the provider with support for debuggers like delve")
    flag.Parse()

    opts := &plugin.ServeOpts{
        ProviderFunc: func() *schema.Provider {
            return Provider()
        },
    }

    if debugMode {
        opts.Debug = true
        opts.ProviderAddr = "registry.terraform.io/hashicorp/custom"
    }

    plugin.Serve(opts)
}
```

### Provider Configuration
```go
// provider.go - Provider configuration
package main

import (
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func Provider() *schema.Provider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "api_url": {
                Type:        schema.TypeString,
                Required:    true,
                DefaultFunc: schema.EnvDefaultFunc("CUSTOM_API_URL", nil),
                Description: "The API URL for the custom service",
            },
            "api_token": {
                Type:        schema.TypeString,
                Required:    true,
                DefaultFunc: schema.EnvDefaultFunc("CUSTOM_API_TOKEN", nil),
                Description: "The API token for authentication",
            },
        },
        ResourcesMap: map[string]*schema.Resource{
            "custom_example": resourceExample(),
        },
        DataSourcesMap: map[string]*schema.Resource{
            "custom_data": dataSourceCustom(),
        },
        ConfigureContextFunc: providerConfigure,
    }
}

func providerConfigure(ctx context.Context, d *schema.ResourceData) (interface{}, error) {
    apiURL := d.Get("api_url").(string)
    apiToken := d.Get("api_token").(string)
    
    // Initialize API client
    client := NewAPIClient(apiURL, apiToken)
    
    return client, nil
}
```

## Resource Implementation

### Basic Resource Structure
```go
// resources/resource_example.go
package main

import (
    "context"
    "fmt"
    "strconv"

    "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func resourceExample() *schema.Resource {
    return &schema.Resource{
        CreateContext: resourceExampleCreate,
        ReadContext:   resourceExampleRead,
        UpdateContext: resourceExampleUpdate,
        DeleteContext: resourceExampleDelete,
        
        Schema: map[string]*schema.Schema{
            "name": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "Name of the example resource",
            },
            "description": {
                Type:        schema.TypeString,
                Optional:    true,
                Description: "Description of the example resource",
            },
            "enabled": {
                Type:        schema.TypeBool,
                Optional:    true,
                Default:     true,
                Description: "Whether the resource is enabled",
            },
            "tags": {
                Type:        schema.TypeMap,
                Optional:    true,
                Elem:        &schema.Schema{Type: schema.TypeString},
                Description: "Tags for the resource",
            },
        },
    }
}

func resourceExampleCreate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    name := d.Get("name").(string)
    description := d.Get("description").(string)
    enabled := d.Get("enabled").(bool)
    tags := d.Get("tags").(map[string]interface{})
    
    // Create resource via API
    resource, err := client.CreateResource(name, description, enabled, tags)
    if err != nil {
        return diag.FromErr(err)
    }
    
    // Set resource ID
    d.SetId(strconv.Itoa(resource.ID))
    
    return resourceExampleRead(ctx, d, m)
}

func resourceExampleRead(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    id := d.Id()
    resourceID, err := strconv.Atoi(id)
    if err != nil {
        return diag.FromErr(err)
    }
    
    // Read resource from API
    resource, err := client.GetResource(resourceID)
    if err != nil {
        return diag.FromErr(err)
    }
    
    // Set resource attributes
    d.Set("name", resource.Name)
    d.Set("description", resource.Description)
    d.Set("enabled", resource.Enabled)
    d.Set("tags", resource.Tags)
    
    return nil
}

func resourceExampleUpdate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    id := d.Id()
    resourceID, err := strconv.Atoi(id)
    if err != nil {
        return diag.FromErr(err)
    }
    
    // Update resource via API
    _, err = client.UpdateResource(resourceID, d)
    if err != nil {
        return diag.FromErr(err)
    }
    
    return resourceExampleRead(ctx, d, m)
}

func resourceExampleDelete(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    id := d.Id()
    resourceID, err := strconv.Atoi(id)
    if err != nil {
        return diag.FromErr(err)
    }
    
    // Delete resource via API
    err = client.DeleteResource(resourceID)
    if err != nil {
        return diag.FromErr(err)
    }
    
    d.SetId("")
    return nil
}
```

## Data Source Implementation

### Data Source Structure
```go
// data_sources/data_source_custom.go
package main

import (
    "context"
    "strconv"

    "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func dataSourceCustom() *schema.Resource {
    return &schema.Resource{
        ReadContext: dataSourceCustomRead,
        
        Schema: map[string]*schema.Schema{
            "id": {
                Type:        schema.TypeInt,
                Required:    true,
                Description: "ID of the resource to retrieve",
            },
            "name": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Name of the resource",
            },
            "description": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Description of the resource",
            },
            "enabled": {
                Type:        schema.TypeBool,
                Computed:    true,
                Description: "Whether the resource is enabled",
            },
            "tags": {
                Type:        schema.TypeMap,
                Computed:    true,
                Elem:        &schema.Schema{Type: schema.TypeString},
                Description: "Tags of the resource",
            },
        },
    }
}

func dataSourceCustomRead(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
    client := m.(*APIClient)
    
    id := d.Get("id").(int)
    
    // Read resource from API
    resource, err := client.GetResource(id)
    if err != nil {
        return diag.FromErr(err)
    }
    
    // Set resource attributes
    d.SetId(strconv.Itoa(resource.ID))
    d.Set("name", resource.Name)
    d.Set("description", resource.Description)
    d.Set("enabled", resource.Enabled)
    d.Set("tags", resource.Tags)
    
    return nil
}
```

## API Client Implementation

### HTTP Client
```go
// client.go - API client implementation
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
)

type APIClient struct {
    baseURL    string
    apiToken   string
    httpClient *http.Client
}

type Resource struct {
    ID          int               `json:"id"`
    Name        string            `json:"name"`
    Description string            `json:"description"`
    Enabled     bool              `json:"enabled"`
    Tags        map[string]string `json:"tags"`
}

func NewAPIClient(baseURL, apiToken string) *APIClient {
    return &APIClient{
        baseURL:  baseURL,
        apiToken: apiToken,
        httpClient: &http.Client{
            Timeout: 30 * time.Second,
        },
    }
}

func (c *APIClient) CreateResource(name, description string, enabled bool, tags map[string]interface{}) (*Resource, error) {
    // Convert tags to string map
    stringTags := make(map[string]string)
    for k, v := range tags {
        stringTags[k] = v.(string)
    }
    
    resource := &Resource{
        Name:        name,
        Description: description,
        Enabled:     enabled,
        Tags:        stringTags,
    }
    
    jsonData, err := json.Marshal(resource)
    if err != nil {
        return nil, err
    }
    
    req, err := http.NewRequest("POST", c.baseURL+"/resources", bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+c.apiToken)
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusCreated {
        return nil, fmt.Errorf("API request failed with status: %d", resp.StatusCode)
    }
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    
    var createdResource Resource
    err = json.Unmarshal(body, &createdResource)
    if err != nil {
        return nil, err
    }
    
    return &createdResource, nil
}

func (c *APIClient) GetResource(id int) (*Resource, error) {
    req, err := http.NewRequest("GET", fmt.Sprintf("%s/resources/%d", c.baseURL, id), nil)
    if err != nil {
        return nil, err
    }
    
    req.Header.Set("Authorization", "Bearer "+c.apiToken)
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("API request failed with status: %d", resp.StatusCode)
    }
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    
    var resource Resource
    err = json.Unmarshal(body, &resource)
    if err != nil {
        return nil, err
    }
    
    return &resource, nil
}

func (c *APIClient) UpdateResource(id int, d *schema.ResourceData) (*Resource, error) {
    resource := &Resource{
        ID:          id,
        Name:        d.Get("name").(string),
        Description: d.Get("description").(string),
        Enabled:     d.Get("enabled").(bool),
    }
    
    // Convert tags
    if tags, ok := d.Get("tags").(map[string]interface{}); ok {
        stringTags := make(map[string]string)
        for k, v := range tags {
            stringTags[k] = v.(string)
        }
        resource.Tags = stringTags
    }
    
    jsonData, err := json.Marshal(resource)
    if err != nil {
        return nil, err
    }
    
    req, err := http.NewRequest("PUT", fmt.Sprintf("%s/resources/%d", c.baseURL, id), bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+c.apiToken)
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("API request failed with status: %d", resp.StatusCode)
    }
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    
    var updatedResource Resource
    err = json.Unmarshal(body, &updatedResource)
    if err != nil {
        return nil, err
    }
    
    return &updatedResource, nil
}

func (c *APIClient) DeleteResource(id int) error {
    req, err := http.NewRequest("DELETE", fmt.Sprintf("%s/resources/%d", c.baseURL, id), nil)
    if err != nil {
        return err
    }
    
    req.Header.Set("Authorization", "Bearer "+c.apiToken)
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusNoContent {
        return fmt.Errorf("API request failed with status: %d", resp.StatusCode)
    }
    
    return nil
}
```

## Testing Strategies

### Unit Testing
```go
// provider_test.go
package main

import (
    "testing"
    
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func TestProvider(t *testing.T) {
    provider := Provider()
    
    if provider == nil {
        t.Fatal("Provider is nil")
    }
    
    if provider.Schema == nil {
        t.Fatal("Provider schema is nil")
    }
    
    // Test required fields
    if provider.Schema["api_url"] == nil {
        t.Fatal("api_url schema is missing")
    }
    
    if provider.Schema["api_token"] == nil {
        t.Fatal("api_token schema is missing")
    }
}
```

### Integration Testing
```go
// resource_test.go
package main

import (
    "testing"
    
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/resource"
    "github.com/hashicorp/terraform-plugin-sdk/v2/terraform"
)

func TestAccResourceExample(t *testing.T) {
    resource.Test(t, resource.TestCase{
        PreCheck:     func() { testAccPreCheck(t) },
        Providers:    testAccProviders,
        CheckDestroy: testAccCheckResourceExampleDestroy,
        Steps: []resource.TestStep{
            {
                Config: testAccResourceExampleConfig(),
                Check: resource.ComposeTestCheckFunc(
                    testAccCheckResourceExampleExists("custom_example.test"),
                    resource.TestCheckResourceAttr("custom_example.test", "name", "test-resource"),
                    resource.TestCheckResourceAttr("custom_example.test", "enabled", "true"),
                ),
            },
        },
    })
}

func testAccPreCheck(t *testing.T) {
    // Pre-check validation
}

func testAccProviders() map[string]*schema.Provider {
    return map[string]*schema.Provider{
        "custom": Provider(),
    }
}

func testAccCheckResourceExampleDestroy(s *terraform.State) error {
    // Check resource destruction
    return nil
}

func testAccCheckResourceExampleExists(n string) resource.TestCheckFunc {
    return func(s *terraform.State) error {
        // Check resource existence
        return nil
    }
}

func testAccResourceExampleConfig() string {
    return `
provider "custom" {
  api_url   = "https://api.example.com"
  api_token = "test-token"
}

resource "custom_example" "test" {
  name        = "test-resource"
  description = "Test resource description"
  enabled     = true
  
  tags = {
    Environment = "test"
    Project     = "terraform-provider"
  }
}
`
}
```

## Provider Distribution

### Building and Distribution
```bash
# Build the provider
go build -o terraform-provider-custom

# Install the provider
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/hashicorp/custom/1.0.0/linux_amd64
cp terraform-provider-custom ~/.terraform.d/plugins/registry.terraform.io/hashicorp/custom/1.0.0/linux_amd64/
```

### Terraform Registry Publishing
```hcl
# Provider configuration for registry
terraform {
  required_providers {
    custom = {
      source  = "hashicorp/custom"
      version = "~> 1.0"
    }
  }
}

provider "custom" {
  api_url   = var.api_url
  api_token = var.api_token
}
```

## Best Practices

### Development Best Practices
- **Error Handling**: Implement comprehensive error handling
- **Validation**: Validate all inputs and outputs
- **Documentation**: Provide comprehensive documentation
- **Testing**: Implement thorough testing strategies
- **Versioning**: Use semantic versioning

### Security Best Practices
- **Authentication**: Implement secure authentication
- **Authorization**: Implement proper authorization
- **Sensitive Data**: Handle sensitive data appropriately
- **Audit Logging**: Enable audit logging
- **Input Validation**: Validate all inputs

## Conclusion

Custom Terraform providers enable integration with custom systems and APIs. By following proper development practices, implementing comprehensive testing, and ensuring security, you can create reliable and maintainable custom providers.

Regular review and updates of custom providers ensure continued effectiveness and adaptation to changing requirements and API changes.
