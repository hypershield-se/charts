# Changelog

All notable changes to the Tetragon Observability Stack Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-20

### Added

#### Core Features
- Initial release of Tetragon Observability Stack umbrella chart
- Integration of three subchart dependencies:
  - Tetragon 1.16.0 (eBPF-based security observability)
  - Fluent Bit 0.47.10 (lightweight log collection)
  - OpenTelemetry Collector 0.97.1 (telemetry processing)

#### Policy Management
- ConfigMap-based policy management with local HTTP server (nginx)
- URL-based policy management for centralized control
- Four pre-configured TracingPolicies:
  - `network-connections` - TCP connect/accept/listen/close (enabled by default)
  - `dns-monitoring` - UDP DNS queries (disabled by default)
  - `http-monitoring` - HTTP/HTTPS traffic on ports 80/443/8080/8443 (disabled by default)
  - `tls-monitoring` - TLS handshakes on ports 443/8443 (disabled by default)
- Mandate file generation with automatic policy references
- Policy server deployment (2 replicas) for serving ConfigMaps via HTTP

#### Fluent Bit Configuration
- Automatic log collection from `/var/run/cilium/tetragon/tetragon.log`
- JSON parsing with Kubernetes metadata enrichment
- OTLP/gRPC output to OpenTelemetry Collector Agent
- Dynamic OTel Collector service name resolution via environment variables
- Connection keepalive settings for persistent connections
- Storage-backed buffering with 10MB memory limit

#### OpenTelemetry Collector Agent
- Enhanced OTLP/gRPC receiver with optimized settings:
  - 16 MiB max message size
  - 100 concurrent streams
  - 524KB read/write buffers
  - Connection keepalive parameters
- Five-stage processor pipeline:
  1. Memory limiter (80% limit, 25% spike)
  2. Resource attribution (cluster, node, namespace, service)
  3. Transform (log enrichment, severity normalization)
  4. Batch processing (1000-2000 logs per batch)
  5. Attributes (deployment environment, collector metadata)
- Optimized OTLP exporter to gateway:
  - zstd compression (60-80% size reduction)
  - Persistent file-backed queue (5000 items)
  - Exponential backoff retry (5s-30s, max 5 minutes)
  - 10 concurrent consumer workers
  - Connection keepalive and 524KB write buffer
- Extensions:
  - File storage for persistent queue at `/var/lib/otelcol/file_storage`
  - Health check endpoint at `:13133/health`
  - Detailed telemetry metrics at `:8888/metrics`

#### Monitoring (Prometheus Operator)
- ServiceMonitor for Tetragon metrics (port 2112)
- ServiceMonitor for Fluent Bit metrics (port 2020, path `/api/v1/metrics/prometheus`)
- ServiceMonitor for OTel Collector Agent metrics (port 8888)
- Configurable scrape intervals and timeouts
- Support for custom relabelings and metric relabelings
- Prometheus label injection support

#### Network Policies
- NetworkPolicy for Tetragon:
  - Ingress: Prometheus metrics, internal gRPC
  - Egress: Kubernetes API, DNS, policy server
- NetworkPolicy for Fluent Bit:
  - Ingress: Prometheus metrics
  - Egress: OTel Collector Agent, DNS, Kubernetes API (optional)
- NetworkPolicy for OTel Collector Agent:
  - Ingress: Fluent Bit logs, Prometheus metrics, health checks
  - Egress: OTel Gateway, DNS

#### Example Values Files
- `minimal.yaml` - Development/testing with minimal resources
  - Single policy (network-connections)
  - 1000 events/min rate limit
  - Minimal CPU/memory allocation
- `production.yaml` - Production deployment with full features
  - URL-based mandate with 5-minute refresh
  - All event types enabled
  - 50,000 events/min rate limit
  - Monitoring and NetworkPolicies enabled
  - Prometheus label integration
- `high-volume.yaml` - High-traffic optimization
  - 100,000 events/min rate limit
  - Large batch sizes (5000 logs)
  - Increased resources and queue sizes
- `low-resource.yaml` - Edge/IoT deployments
  - 50m CPU, 64Mi memory for Tetragon
  - Limited event types (CONNECT, CLOSE only)
  - Aggressive filtering

#### Documentation
- Comprehensive README.md with:
  - Architecture diagrams
  - Installation instructions
  - Configuration reference
  - Deployment examples (4 scenarios)
  - Customization guides
  - Troubleshooting section
  - Performance tuning recommendations
  - Security considerations
- NOTES.txt with post-install instructions:
  - Component status
  - Policy server URL
  - Verification commands
  - Gateway connection test
- GitHub Pages setup guide (GITHUB_PAGES_SETUP.md)
- Apache 2.0 LICENSE

#### GitHub Actions
- Automated chart release workflow:
  - Lint and test with chart-testing
  - Chart packaging with chart-releaser
  - GitHub releases creation
  - GitHub Pages deployment
- Configuration files:
  - `.github/workflows/release-chart.yml` - Main workflow
  - `.github/cr.yaml` - Chart releaser config
  - `.github/ct.yaml` - Chart testing config

#### Helper Templates
- `tetragon-observability-stack.name` - Chart name helper
- `tetragon-observability-stack.fullname` - Full name with release
- `tetragon-observability-stack.chart` - Chart version string
- `tetragon-observability-stack.labels` - Common labels
- `tetragon-observability-stack.selectorLabels` - Selector labels
- `tetragon-observability-stack.serviceAccountName` - Service account name
- `tetragon-observability-stack.namespace` - Target namespace
- `tetragon-observability-stack.validateValues` - Values validation
- `tetragon-observability-stack.policiesConfigMapName` - Policies ConfigMap name
- `tetragon-observability-stack.mandateConfigMapName` - Mandate ConfigMap name

### Configuration

#### Global Settings
- `global.clusterName` - Cluster identifier (default: "my-cluster")
- `global.namespace` - Deployment namespace (default: from .Release.Namespace)
- `global.otelGatewayEndpoint` - OTel Gateway endpoint (REQUIRED)
- `global.otelGatewayTLS.enabled` - Enable TLS for gateway (default: false)
- `global.otelGatewayTLS.insecure` - Skip TLS verification (default: true)

#### Policy Management
- `policies.mandateSource` - "configmap" or "url" (default: "configmap")
- `policies.mandateUrl` - URL for remote mandate (required if source is "url")
- `policies.mandateRefreshPeriod` - Refresh interval (default: "1m0s")
- `policies.mandate.enabled` - Enable mandate generation (default: true)
- `policies.mandate.mode` - "monitor" or "enforce" (default: "monitor")
- `policies.mandate.info.version` - Mandate version (default: "1.0.0")
- `policies.mandate.info.description` - Mandate description
- `policies.mandate.info.owner` - Policy owner

#### Resource Limits
Default resource allocations:
- Tetragon: 1000m CPU / 1Gi memory (limits), 100m CPU / 128Mi memory (requests)
- Fluent Bit: 200m CPU / 100Mi memory (limits), 100m CPU / 50Mi memory (requests)
- OTel Agent: 500m CPU / 500Mi memory (limits), 200m CPU / 200Mi memory (requests)

### Dependencies
- Tetragon: 1.16.0 from https://helm.isovalent.com
- Fluent Bit: 0.47.10 from https://fluent.github.io/helm-charts
- OpenTelemetry Collector: 0.97.1 from https://open-telemetry.github.io/opentelemetry-helm-charts

### Known Limitations
- Template expressions in `values.yaml` don't work for subchart values
  - Users must override `CLUSTER_NAME` and `OTEL_SERVICE_NAME` in example values
- OTel Gateway (Layer 5) not included - must be deployed separately
- Chart version locked to specific Tetragon version (1.16.x)
- Requires Kubernetes 1.21+
- Requires Linux kernel 5.10+ for eBPF

### Upgrade Notes
- This is the initial release, no upgrade path exists yet
- Future versions will document upgrade procedures and breaking changes

## [Unreleased]

### Planned
- Support for multiple Tetragon versions
- Grafana dashboard templates
- Alert rules for Prometheus Alertmanager
- Additional TracingPolicies (file I/O, syscalls, kernel events)
- Helm tests for chart validation
- Support for custom CA certificates
- Multi-cluster policy synchronization
