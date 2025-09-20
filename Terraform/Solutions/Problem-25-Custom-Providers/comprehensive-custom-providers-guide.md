# Terraform Custom Providers - Complete Development Guide

## Overview

This comprehensive guide covers custom Terraform provider development, including provider architecture, resource implementation, testing strategies, and distribution methods for enterprise environments.

## Provider Architecture Fundamentals

### What are Custom Providers?

Custom providers extend Terraform's capabilities to manage:
- **Internal APIs**: Company-specific services and tools
- **Third-party Services**: Services without official providers
- **Custom Resources**: Specialized infrastructure components
- **Legacy Systems**: Integration with existing systems

### Provider Components

```go
// Provider structure
type Provider struct {
    Schema         map[string]*schema.Schema
    ResourcesMap   map[string]*schema.Resource
    DataSourcesMap map[string]*schema.Resource
    ConfigureFunc  func(*schema.ResourceData) (interface{}, error)
}
```

## Provider Development Setup

### Development Environment

```bash
# Install Go
curl -LO https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Setup provider project
mkdir terraform-provider-myservice
cd terraform-provider-myservice
go mod init terraform-provider-myservice

# Install Terraform Plugin SDK
go get github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema
go get github.com/hashicorp/terraform-plugin-sdk/v2/plugin
```

### Project Structure

```
terraform-provider-myservice/
├── main.go                    # Provider entry point
├── provider/
│   ├── provider.go           # Provider configuration
│   ├── resource_server.go    # Server resource
│   ├── resource_database.go  # Database resource
│   └── data_source_image.go  # Image data source
├── client/
│   ├── client.go            # API client
│   └── models.go            # Data models
├── docs/                    # Documentation
├── examples/               # Usage examples
└── tests/                  # Integration tests
```

## Basic Provider Implementation

### Provider Entry Point

```go
// main.go
package main

import (
    "context"
    "flag"
    "log"

    "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
    "terraform-provider-myservice/provider"
)

func main() {
    var debugMode bool
    flag.BoolVar(&debugMode, "debug", false, "set to true to run the provider with support for debuggers")
    flag.Parse()

    opts := &plugin.ServeOpts{
        ProviderFunc: provider.Provider,
        Debug:        debugMode,
    }

    plugin.Serve(opts)
}
```

### Provider Configuration

```go
// provider/provider.go
package provider

import (
    "context"
    "terraform-provider-myservice/client"

    "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func Provider() *schema.Provider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "api_url": {
                Type:        schema.TypeString,
                Required:    true,
                DefaultFunc: schema.EnvDefaultFunc("MYSERVICE_API_URL", nil),
                Description: "The API URL for MyService",
            },
            "api_token": {
                Type:        schema.TypeString,
                Required:    true,
                Sensitive:   true,
                DefaultFunc: schema.EnvDefaultFunc("MYSERVICE_API_TOKEN", nil),
                Description: "The API token for MyService",
            },
            "timeout": {
                Type:        schema.TypeInt,
                Optional:    true,
                Default:     30,
                Description: "Request timeout in seconds",
            },
        },
        ResourcesMap: map[string]*schema.Resource{
            "myservice_server":   resourceServer(),
            "myservice_database": resourceDatabase(),
        },
        DataSourcesMap: map[string]*schema.Resource{
            "myservice_image": dataSourceImage(),
        },
        ConfigureContextFunc: providerConfigure,
    }
}

func providerConfigure(ctx context.Context, d *schema.ResourceData) (interface{}, diag.Diagnostics) {
    apiURL := d.Get("api_url").(string)
    apiToken := d.Get("api_token").(string)
    timeout := d.Get("timeout").(int)

    var diags diag.Diagnostics

    if apiURL == "" {
        diags = append(diags, diag.Diagnostic{
            Severity: diag.Error,
            Summary:  "Unable to create MyService client",
            Detail:   "API URL is required",
        })
        return nil, diags
    }

    c, err := client.NewClient(apiURL, apiToken, timeout)
    if err != nil {
        diags = append(diags, diag.Diagnostic{
            Severity: diag.Error,
            Summary:  "Unable to create MyService client",
            Detail:   err.Error(),
        })
        return nil, diags
    }

    return c, diags
}
```

## Resource Implementation

### Server Resource

```go
// provider/resource_server.go
package provider

import (
    "context"
    "strconv"
    "time"

    "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
    "terraform-provider-myservice/client"
)

func resourceServer() *schema.Resource {
    return &schema.Resource{
        CreateContext: resourceServerCreate,
        ReadContext:   resourceServerRead,
        UpdateContext: resourceServerUpdate,
        DeleteContext: resourceServerDelete,
        
        Schema: map[string]*schema.Schema{
            "name": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "Server name",
            },
            "size": {
                Type:        schema.TypeString,
                Required:    true,
                Description: "Server size (small, medium, large)",
                ValidateFunc: func(val interface{}, key string) (warns []string, errs []error) {
                    v := val.(string)
                    validSizes := []string{"small", "medium", "large"}
                    for _, size := range validSizes {
                        if v == size {
                            return
                        }
                    }
                    errs = append(errs, fmt.Errorf("%q must be one of %v", key, validSizes))
                    return
                },
            },
            "region": {
                Type:        schema.TypeString,
                Required:    true,
                ForceNew:    true,
                Description: "Server region",
            },
            "tags": {
                Type:        schema.TypeMap,
                Optional:    true,
                Elem:        &schema.Schema{Type: schema.TypeString},
                Description: "Server tags",
            },
            "ip_address": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Server IP address",
            },
            "status": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Server status",
            },
            "created_at": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Server creation timestamp",
            },
        },
        
        Timeouts: &schema.ResourceTimeout{
            Create: schema.DefaultTimeout(10 * time.Minute),
            Update: schema.DefaultTimeout(10 * time.Minute),
            Delete: schema.DefaultTimeout(10 * time.Minute),
        },
    }
}

func resourceServerCreate(ctx context.Context, d *schema.ResourceData, meta interface{}) diag.Diagnostics {
    c := meta.(*client.Client)
    
    var diags diag.Diagnostics
    
    server := client.Server{
        Name:   d.Get("name").(string),
        Size:   d.Get("size").(string),
        Region: d.Get("region").(string),
        Tags:   expandTags(d.Get("tags").(map[string]interface{})),
    }
    
    createdServer, err := c.CreateServer(ctx, server)
    if err != nil {
        return diag.FromErr(err)
    }
    
    d.SetId(strconv.Itoa(createdServer.ID))
    
    // Wait for server to be ready
    err = waitForServerReady(ctx, c, createdServer.ID, d.Timeout(schema.TimeoutCreate))
    if err != nil {
        return diag.FromErr(err)
    }
    
    return resourceServerRead(ctx, d, meta)
}

func resourceServerRead(ctx context.Context, d *schema.ResourceData, meta interface{}) diag.Diagnostics {
    c := meta.(*client.Client)
    
    var diags diag.Diagnostics
    
    serverID, err := strconv.Atoi(d.Id())
    if err != nil {
        return diag.FromErr(err)
    }
    
    server, err := c.GetServer(ctx, serverID)
    if err != nil {
        if client.IsNotFoundError(err) {
            d.SetId("")
            return diags
        }
        return diag.FromErr(err)
    }
    
    d.Set("name", server.Name)
    d.Set("size", server.Size)
    d.Set("region", server.Region)
    d.Set("ip_address", server.IPAddress)
    d.Set("status", server.Status)
    d.Set("created_at", server.CreatedAt.Format(time.RFC3339))
    d.Set("tags", flattenTags(server.Tags))
    
    return diags
}

func resourceServerUpdate(ctx context.Context, d *schema.ResourceData, meta interface{}) diag.Diagnostics {
    c := meta.(*client.Client)
    
    serverID, err := strconv.Atoi(d.Id())
    if err != nil {
        return diag.FromErr(err)
    }
    
    if d.HasChanges("name", "size", "tags") {
        server := client.Server{
            ID:   serverID,
            Name: d.Get("name").(string),
            Size: d.Get("size").(string),
            Tags: expandTags(d.Get("tags").(map[string]interface{})),
        }
        
        _, err := c.UpdateServer(ctx, server)
        if err != nil {
            return diag.FromErr(err)
        }
        
        // Wait for update to complete
        err = waitForServerReady(ctx, c, serverID, d.Timeout(schema.TimeoutUpdate))
        if err != nil {
            return diag.FromErr(err)
        }
    }
    
    return resourceServerRead(ctx, d, meta)
}

func resourceServerDelete(ctx context.Context, d *schema.ResourceData, meta interface{}) diag.Diagnostics {
    c := meta.(*client.Client)
    
    var diags diag.Diagnostics
    
    serverID, err := strconv.Atoi(d.Id())
    if err != nil {
        return diag.FromErr(err)
    }
    
    err = c.DeleteServer(ctx, serverID)
    if err != nil {
        if !client.IsNotFoundError(err) {
            return diag.FromErr(err)
        }
    }
    
    // Wait for deletion to complete
    err = waitForServerDeleted(ctx, c, serverID, d.Timeout(schema.TimeoutDelete))
    if err != nil {
        return diag.FromErr(err)
    }
    
    d.SetId("")
    return diags
}
```

## Data Source Implementation

### Image Data Source

```go
// provider/data_source_image.go
package provider

import (
    "context"
    "strconv"

    "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
    "terraform-provider-myservice/client"
)

func dataSourceImage() *schema.Resource {
    return &schema.Resource{
        ReadContext: dataSourceImageRead,
        
        Schema: map[string]*schema.Schema{
            "name": {
                Type:        schema.TypeString,
                Optional:    true,
                Description: "Image name filter",
            },
            "os": {
                Type:        schema.TypeString,
                Optional:    true,
                Description: "Operating system filter",
            },
            "version": {
                Type:        schema.TypeString,
                Optional:    true,
                Description: "Version filter",
            },
            "most_recent": {
                Type:        schema.TypeBool,
                Optional:    true,
                Default:     false,
                Description: "Return most recent image",
            },
            "image_id": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Image ID",
            },
            "description": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Image description",
            },
            "created_at": {
                Type:        schema.TypeString,
                Computed:    true,
                Description: "Image creation timestamp",
            },
        },
    }
}

func dataSourceImageRead(ctx context.Context, d *schema.ResourceData, meta interface{}) diag.Diagnostics {
    c := meta.(*client.Client)
    
    var diags diag.Diagnostics
    
    filters := client.ImageFilters{
        Name:    d.Get("name").(string),
        OS:      d.Get("os").(string),
        Version: d.Get("version").(string),
    }
    
    images, err := c.ListImages(ctx, filters)
    if err != nil {
        return diag.FromErr(err)
    }
    
    if len(images) == 0 {
        return diag.Errorf("No images found matching the specified criteria")
    }
    
    var selectedImage client.Image
    if d.Get("most_recent").(bool) {
        selectedImage = images[0] // Assuming API returns sorted by creation date
    } else {
        if len(images) > 1 {
            return diag.Errorf("Multiple images found. Use most_recent = true or add more specific filters")
        }
        selectedImage = images[0]
    }
    
    d.SetId(strconv.Itoa(selectedImage.ID))
    d.Set("image_id", selectedImage.ID)
    d.Set("name", selectedImage.Name)
    d.Set("description", selectedImage.Description)
    d.Set("created_at", selectedImage.CreatedAt.Format(time.RFC3339))
    
    return diags
}
```

## API Client Implementation

### HTTP Client

```go
// client/client.go
package client

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

type Client struct {
    HTTPClient *http.Client
    BaseURL    string
    Token      string
}

func NewClient(baseURL, token string, timeout int) (*Client, error) {
    return &Client{
        HTTPClient: &http.Client{
            Timeout: time.Duration(timeout) * time.Second,
        },
        BaseURL: baseURL,
        Token:   token,
    }, nil
}

func (c *Client) doRequest(ctx context.Context, method, path string, body interface{}) (*http.Response, error) {
    var reqBody []byte
    var err error
    
    if body != nil {
        reqBody, err = json.Marshal(body)
        if err != nil {
            return nil, err
        }
    }
    
    req, err := http.NewRequestWithContext(ctx, method, c.BaseURL+path, bytes.NewBuffer(reqBody))
    if err != nil {
        return nil, err
    }
    
    req.Header.Set("Authorization", "Bearer "+c.Token)
    req.Header.Set("Content-Type", "application/json")
    
    return c.HTTPClient.Do(req)
}

func (c *Client) CreateServer(ctx context.Context, server Server) (*Server, error) {
    resp, err := c.doRequest(ctx, "POST", "/servers", server)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusCreated {
        return nil, fmt.Errorf("failed to create server: %s", resp.Status)
    }
    
    var createdServer Server
    err = json.NewDecoder(resp.Body).Decode(&createdServer)
    if err != nil {
        return nil, err
    }
    
    return &createdServer, nil
}

func (c *Client) GetServer(ctx context.Context, id int) (*Server, error) {
    resp, err := c.doRequest(ctx, "GET", fmt.Sprintf("/servers/%d", id), nil)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode == http.StatusNotFound {
        return nil, &NotFoundError{Resource: "server", ID: id}
    }
    
    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("failed to get server: %s", resp.Status)
    }
    
    var server Server
    err = json.NewDecoder(resp.Body).Decode(&server)
    if err != nil {
        return nil, err
    }
    
    return &server, nil
}
```

## Provider Testing

### Unit Tests

```go
// provider/resource_server_test.go
package provider

import (
    "fmt"
    "testing"

    "github.com/hashicorp/terraform-plugin-sdk/v2/helper/resource"
    "github.com/hashicorp/terraform-plugin-sdk/v2/terraform"
)

func TestAccResourceServer_basic(t *testing.T) {
    resource.Test(t, resource.TestCase{
        PreCheck:     func() { testAccPreCheck(t) },
        Providers:    testAccProviders,
        CheckDestroy: testAccCheckServerDestroy,
        Steps: []resource.TestStep{
            {
                Config: testAccResourceServerConfig_basic(),
                Check: resource.ComposeTestCheckFunc(
                    testAccCheckServerExists("myservice_server.test"),
                    resource.TestCheckResourceAttr("myservice_server.test", "name", "test-server"),
                    resource.TestCheckResourceAttr("myservice_server.test", "size", "small"),
                    resource.TestCheckResourceAttr("myservice_server.test", "region", "us-west-1"),
                    resource.TestCheckResourceAttrSet("myservice_server.test", "ip_address"),
                    resource.TestCheckResourceAttrSet("myservice_server.test", "status"),
                ),
            },
        },
    })
}

func TestAccResourceServer_update(t *testing.T) {
    resource.Test(t, resource.TestCase{
        PreCheck:     func() { testAccPreCheck(t) },
        Providers:    testAccProviders,
        CheckDestroy: testAccCheckServerDestroy,
        Steps: []resource.TestStep{
            {
                Config: testAccResourceServerConfig_basic(),
                Check: resource.ComposeTestCheckFunc(
                    testAccCheckServerExists("myservice_server.test"),
                    resource.TestCheckResourceAttr("myservice_server.test", "size", "small"),
                ),
            },
            {
                Config: testAccResourceServerConfig_updated(),
                Check: resource.ComposeTestCheckFunc(
                    testAccCheckServerExists("myservice_server.test"),
                    resource.TestCheckResourceAttr("myservice_server.test", "size", "medium"),
                    resource.TestCheckResourceAttr("myservice_server.test", "tags.%", "2"),
                ),
            },
        },
    })
}

func testAccResourceServerConfig_basic() string {
    return `
resource "myservice_server" "test" {
  name   = "test-server"
  size   = "small"
  region = "us-west-1"
}
`
}

func testAccResourceServerConfig_updated() string {
    return `
resource "myservice_server" "test" {
  name   = "test-server"
  size   = "medium"
  region = "us-west-1"
  
  tags = {
    Environment = "test"
    Purpose     = "testing"
  }
}
`
}

func testAccCheckServerExists(resourceName string) resource.TestCheckFunc {
    return func(s *terraform.State) error {
        rs, ok := s.RootModule().Resources[resourceName]
        if !ok {
            return fmt.Errorf("Resource not found: %s", resourceName)
        }
        
        if rs.Primary.ID == "" {
            return fmt.Errorf("No server ID is set")
        }
        
        // Additional existence check would go here
        return nil
    }
}
```

### Integration Tests

```go
// tests/integration_test.go
package tests

import (
    "context"
    "os"
    "testing"
    "time"

    "terraform-provider-myservice/client"
)

func TestClientIntegration(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping integration test")
    }
    
    apiURL := os.Getenv("MYSERVICE_API_URL")
    apiToken := os.Getenv("MYSERVICE_API_TOKEN")
    
    if apiURL == "" || apiToken == "" {
        t.Skip("MYSERVICE_API_URL and MYSERVICE_API_TOKEN must be set for integration tests")
    }
    
    c, err := client.NewClient(apiURL, apiToken, 30)
    if err != nil {
        t.Fatalf("Failed to create client: %v", err)
    }
    
    ctx := context.Background()
    
    // Test server creation
    server := client.Server{
        Name:   "integration-test-server",
        Size:   "small",
        Region: "us-west-1",
        Tags: map[string]string{
            "test": "integration",
        },
    }
    
    createdServer, err := c.CreateServer(ctx, server)
    if err != nil {
        t.Fatalf("Failed to create server: %v", err)
    }
    
    defer func() {
        err := c.DeleteServer(ctx, createdServer.ID)
        if err != nil {
            t.Errorf("Failed to cleanup server: %v", err)
        }
    }()
    
    // Test server retrieval
    retrievedServer, err := c.GetServer(ctx, createdServer.ID)
    if err != nil {
        t.Fatalf("Failed to get server: %v", err)
    }
    
    if retrievedServer.Name != server.Name {
        t.Errorf("Expected server name %s, got %s", server.Name, retrievedServer.Name)
    }
}
```

## Provider Documentation

### Resource Documentation

```markdown
# myservice_server

Manages a server in MyService.

## Example Usage

```hcl
resource "myservice_server" "web" {
  name   = "web-server"
  size   = "medium"
  region = "us-west-1"
  
  tags = {
    Environment = "production"
    Role        = "web"
  }
}
```

## Argument Reference

* `name` - (Required) The name of the server.
* `size` - (Required) The size of the server. Valid values are `small`, `medium`, `large`.
* `region` - (Required) The region where the server will be created.
* `tags` - (Optional) A map of tags to assign to the server.

## Attributes Reference

* `id` - The ID of the server.
* `ip_address` - The IP address of the server.
* `status` - The current status of the server.
* `created_at` - The timestamp when the server was created.

## Timeouts

* `create` - (Default 10 minutes) How long to wait for server creation.
* `update` - (Default 10 minutes) How long to wait for server updates.
* `delete` - (Default 10 minutes) How long to wait for server deletion.

## Import

Servers can be imported using the server ID:

```
terraform import myservice_server.web 12345
```
```

## Provider Distribution

### Building the Provider

```bash
# Build for current platform
go build -o terraform-provider-myservice

# Build for multiple platforms
GOOS=linux GOARCH=amd64 go build -o terraform-provider-myservice_linux_amd64
GOOS=darwin GOARCH=amd64 go build -o terraform-provider-myservice_darwin_amd64
GOOS=windows GOARCH=amd64 go build -o terraform-provider-myservice_windows_amd64.exe
```

### Local Installation

```bash
# Create provider directory
mkdir -p ~/.terraform.d/plugins/local/mycompany/myservice/1.0.0/linux_amd64

# Copy provider binary
cp terraform-provider-myservice ~/.terraform.d/plugins/local/mycompany/myservice/1.0.0/linux_amd64/
```

### Registry Publication

```hcl
# terraform-registry.tf
terraform {
  required_providers {
    myservice = {
      source  = "mycompany/myservice"
      version = "~> 1.0"
    }
  }
}
```

## Best Practices

### Error Handling

```go
// Custom error types
type NotFoundError struct {
    Resource string
    ID       int
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s with ID %d not found", e.Resource, e.ID)
}

func IsNotFoundError(err error) bool {
    _, ok := err.(*NotFoundError)
    return ok
}
```

### Retry Logic

```go
// Retry with exponential backoff
func waitForServerReady(ctx context.Context, c *client.Client, id int, timeout time.Duration) error {
    ctx, cancel := context.WithTimeout(ctx, timeout)
    defer cancel()
    
    for {
        server, err := c.GetServer(ctx, id)
        if err != nil {
            return err
        }
        
        if server.Status == "ready" {
            return nil
        }
        
        if server.Status == "error" {
            return fmt.Errorf("server entered error state")
        }
        
        select {
        case <-ctx.Done():
            return fmt.Errorf("timeout waiting for server to be ready")
        case <-time.After(10 * time.Second):
            // Continue polling
        }
    }
}
```

### Validation

```go
// Input validation
func validateServerSize(val interface{}, key string) (warns []string, errs []error) {
    v := val.(string)
    validSizes := []string{"small", "medium", "large", "xlarge"}
    
    for _, size := range validSizes {
        if v == size {
            return
        }
    }
    
    errs = append(errs, fmt.Errorf("%q must be one of %v, got: %s", key, validSizes, v))
    return
}
```

## Conclusion

Custom provider development enables:
- **API Integration**: Connect Terraform to any API
- **Resource Management**: Manage custom infrastructure components
- **Workflow Integration**: Integrate with existing tools and processes
- **Enterprise Solutions**: Build company-specific infrastructure automation

Key takeaways:
- Follow Terraform Plugin SDK patterns
- Implement comprehensive error handling
- Include thorough testing
- Provide clear documentation
- Follow semantic versioning
- Consider provider lifecycle management
