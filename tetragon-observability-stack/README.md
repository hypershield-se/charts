# Tetragon Observability Stack

Complete observability stack for Cilium Tetragon with Fluent Bit and OpenTelemetry Collector integration.

## Overview

This Helm chart deploys a comprehensive eBPF-based observability solution that combines:

- **Tetragon**: Runtime security observability using eBPF
- **Fluent Bit**: Lightweight log collection and forwarding
- **OpenTelemetry Collector**: Cloud-native telemetry processing

The stack implements a proven architecture for collecting, processing, and forwarding Tetragon events at scale.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Worker Node                       │
│  ┌────────────────────┐                                             │
│  │   Tetragon Pod     │◄────── TracingPolicies from Mandate         │
│  └─────────┬──────────┘                                             │
│            │ JSON logs to file                                      │
│            ▼                                                         │
│  ┌────────────────────┐                                             │
│  │  Fluent Bit Pod    │  - Parses JSON events                       │
│  │  (DaemonSet)       │  - Enriches with K8s metadata               │
│  └─────────┬──────────┘  - Forwards via OTLP/gRPC                   │
│            ▼                                                         │
│  ┌────────────────────┐                                             │
│  │  OTel Collector    │  - Compresses with zstd                     │
│  │  Agent (DaemonSet) │  - Reduces traffic by 60-80%                │
│  └─────────┬──────────┘                                             │
└────────────┼─────────────────────────────────────────────────────────┘
             │ OTLP/gRPC (compressed, batched)
             ▼
    ┌────────────────────────┐
    │   OTel Gateway         │  ← Deployed separately
    │   (User's environment) │
    └────────────────────────┘
```

**Layers Deployed**:
- Layer 1: Policy Management (mandate ConfigMaps or URL)
- Layer 2: Event Generation (Tetragon DaemonSet)
- Layer 3: Log Collection (Fluent Bit DaemonSet)
- Layer 4: Node Processing (OTel Collector Agent DaemonSet)

**Layer 5 (OTel Gateway)** is NOT included - you must deploy it separately in your environment.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.8+
- Linux kernel 5.10+ (for Tetragon eBPF programs)
- OpenTelemetry Collector Gateway deployed separately (required)

## Installation

### Add Helm Repository

```bash
helm repo add tetragon-observability https://hypershield-se.github.io/merge
helm repo update
```

### Install Chart

```bash
helm install tetragon-stack tetragon-observability/tetragon-observability-stack \
  --namespace tetragon \
  --create-namespace \
  --set global.clusterName="my-cluster" \
  --set global.otelGatewayEndpoint="otel-gateway.monitoring.svc:4317"
```

### Verify Installation

```bash
# Check all pods are running
kubectl get pods -n tetragon

# View Tetragon events
kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout --tail=20

# Check Fluent Bit is collecting
kubectl logs -n tetragon daemonset/tetragon-stack-fluent-bit --tail=20

# Verify OTel Agent metrics
kubectl port-forward -n tetragon daemonset/tetragon-stack-opentelemetry-collector 8888:8888
curl http://localhost:8888/metrics | grep otelcol_receiver
```

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.clusterName` | Cluster identifier for telemetry | `"my-cluster"` |
| `global.namespace` | Namespace for deployment | `tetragon` |
| `global.otelGatewayEndpoint` | OTel Gateway endpoint (required) | `""` |
| `global.otelGatewayTLS.enabled` | Enable TLS for gateway connection | `false` |

### Policy Management

| Parameter | Description | Default |
|-----------|-------------|---------|
| `policies.mandateSource` | Mandate source: `configmap` or `url` | `"configmap"` |
| `policies.mandateUrl` | URL for remote mandate file | `""` |
| `policies.mandateRefreshPeriod` | Refresh interval for URL-based mandate | `"1h"` |
| `policies.mandate.enabled` | Enable mandate file generation | `true` |
| `policies.mandate.mode` | Policy enforcement mode: `monitor` or `enforce` | `"monitor"` |

### TracingPolicies

| Parameter | Description | Default |
|-----------|-------------|---------|
| `policies.tracingPolicies.networkConnections.enabled` | Enable network connection tracing | `true` |
| `policies.tracingPolicies.dnsMonitoring.enabled` | Enable DNS query monitoring | `false` |
| `policies.tracingPolicies.httpMonitoring.enabled` | Enable HTTP request monitoring | `false` |
| `policies.tracingPolicies.tlsMonitoring.enabled` | Enable TLS connection monitoring | `false` |

### Tetragon Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tetragon.enabled` | Enable Tetragon DaemonSet | `true` |
| `tetragon.exportAllowList` | Event types to export | See `values.yaml` |
| `tetragon.exportDenyList` | Events to filter out | See `values.yaml` |
| `tetragon.exportRateLimit` | Events per minute limit | `10000` |
| `tetragon.eventQueueSize` | Event queue buffer size | `10000` |
| `tetragon.resources.limits.cpu` | CPU limit | `1000m` |
| `tetragon.resources.limits.memory` | Memory limit | `1Gi` |

### Fluent Bit Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `fluentbit.enabled` | Enable Fluent Bit DaemonSet | `true` |
| `fluentbit.resources.limits.cpu` | CPU limit | `200m` |
| `fluentbit.resources.limits.memory` | Memory limit | `100Mi` |

### OpenTelemetry Collector Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `otelAgent.enabled` | Enable OTel Collector Agent | `true` |
| `otelAgent.mode` | Deployment mode | `daemonset` |
| `otelAgent.config.processors.batch.send_batch_max_size` | Max batch size | `2000` |
| `otelAgent.config.processors.batch.timeout` | Batch timeout | `1s` |
| `otelAgent.resources.limits.cpu` | CPU limit | `500m` |
| `otelAgent.resources.limits.memory` | Memory limit | `500Mi` |

### Monitoring

| Parameter | Description | Default |
|-----------|-------------|---------|
| `monitoring.enabled` | Create ServiceMonitors for Prometheus | `false` |
| `networkPolicies.enabled` | Create NetworkPolicies | `false` |

## Deployment Examples

### Minimal (Development/Testing)

```bash
helm install tetragon-stack tetragon-observability/tetragon-observability-stack \
  --namespace tetragon \
  --create-namespace \
  --values values-examples/minimal.yaml \
  --set global.otelGatewayEndpoint="otel-gateway.default.svc:4317"
```

**Features**:
- Single policy (network-connections)
- Minimal resource allocation
- ConfigMap-based mandate
- No monitoring or network policies

**Use Cases**: Local development, proof-of-concept, testing

### Production

```bash
helm install tetragon-stack tetragon-observability/tetragon-observability-stack \
  --namespace tetragon \
  --create-namespace \
  --values values-examples/production.yaml \
  --set policies.mandateUrl="https://policies.example.com/tetragon/mandate.yaml" \
  --set global.otelGatewayEndpoint="otel-gateway.monitoring.svc:4317"
```

**Features**:
- URL-based mandate (centralized policy management)
- All policies enabled
- Prometheus ServiceMonitors
- NetworkPolicies for security
- Production resource limits

**Use Cases**: Production clusters, multi-cluster deployments

### High-Volume

```bash
helm install tetragon-stack tetragon-observability/tetragon-observability-stack \
  --namespace tetragon \
  --create-namespace \
  --values values-examples/high-volume.yaml \
  --set global.otelGatewayEndpoint="otel-gateway.monitoring.svc:4317"
```

**Features**:
- Rate limit: 100,000 events/min
- Large batch sizes (5000)
- Aggressive compression (zstd)
- Increased resource allocation

**Use Cases**: Large clusters (100+ nodes), high-traffic environments

### Low-Resource (Edge/IoT)

```bash
helm install tetragon-stack tetragon-observability/tetragon-observability-stack \
  --namespace tetragon \
  --create-namespace \
  --values values-examples/low-resource.yaml \
  --set global.otelGatewayEndpoint="otel-gateway.default.svc:4317"
```

**Features**:
- Minimal CPU (50m) and memory (64Mi)
- Limited event types
- Aggressive filtering
- No monitoring overhead

**Use Cases**: Edge clusters, IoT gateways, resource-constrained environments

## Customization

### Custom Mandate File

For ConfigMap-based mandate:

```yaml
policies:
  mandateSource: "configmap"
  mandate:
    enabled: true
    info:
      version: "1.0.0"
      description: "Custom security policies"
      owner: "security-team@example.com"
    mode: "enforce"
    policies:
      - name: network-connections
        enabled: true
        mode: "monitor"
      - name: dns-monitoring
        enabled: true
```

For URL-based mandate:

```yaml
policies:
  mandateSource: "url"
  mandateUrl: "https://policies.example.com/tetragon/mandate.yaml"
  mandateRefreshPeriod: "30m"
```

### Custom TracingPolicy

Add custom policies to the ConfigMap:

```yaml
policies:
  tracingPolicies:
    customPolicy:
      enabled: true
      policy: |
        apiVersion: cilium.io/v1alpha1
        kind: TracingPolicy
        metadata:
          name: custom-policy
        spec:
          kprobes:
          - call: "sys_read"
            syscall: true
            args:
            - index: 0
              type: "int"
```

### Custom Fluent Bit Filters

Add custom filters to Fluent Bit configuration:

```yaml
fluentbit:
  config:
    filters: |
      [FILTER]
          Name                modify
          Match               *
          Add                 environment production
          Add                 region us-west-2
```

### Custom OTel Processors

Add custom processors to OTel Collector:

```yaml
otelAgent:
  config:
    processors:
      attributes:
        actions:
          - key: deployment.environment
            value: production
            action: insert
      resource:
        attributes:
          - key: k8s.cluster.name
            value: ${CLUSTER_NAME}
            action: insert
```

## Upgrading

### Update Repository

```bash
helm repo update tetragon-observability
```

### Upgrade Release

```bash
helm upgrade tetragon-stack tetragon-observability/tetragon-observability-stack \
  --namespace tetragon \
  --reuse-values
```

### Upgrade with New Values

```bash
helm upgrade tetragon-stack tetragon-observability/tetragon-observability-stack \
  --namespace tetragon \
  --values my-values.yaml
```

## Uninstallation

```bash
helm uninstall tetragon-stack --namespace tetragon
```

This will remove all resources created by the chart. To also delete the namespace:

```bash
kubectl delete namespace tetragon
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n tetragon

# Check pod events
kubectl describe pod -n tetragon <pod-name>

# Check logs
kubectl logs -n tetragon <pod-name>
```

### No Events Flowing

```bash
# Verify Tetragon is generating events
kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout --tail=50

# Check Fluent Bit is reading logs
kubectl logs -n tetragon daemonset/tetragon-stack-fluent-bit --tail=50

# Verify OTel Agent is receiving data
kubectl port-forward -n tetragon daemonset/tetragon-stack-opentelemetry-collector 8888:8888
curl http://localhost:8888/metrics | grep otelcol_receiver_accepted
```

### High Memory Usage

```bash
# Check resource usage
kubectl top pods -n tetragon

# Reduce event volume with filters
helm upgrade tetragon-stack tetragon-observability/tetragon-observability-stack \
  --set tetragon.exportRateLimit=5000 \
  --reuse-values
```

### Gateway Connection Issues

```bash
# Check OTel Agent logs
kubectl logs -n tetragon daemonset/tetragon-stack-opentelemetry-collector

# Verify gateway endpoint
kubectl get endpoints -n monitoring otel-gateway

# Test connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- \
  nc -zv otel-gateway.monitoring.svc 4317
```

### Policy Not Loading

```bash
# Check mandate ConfigMap
kubectl get configmap -n tetragon tetragon-stack-mandate -o yaml

# Check policy ConfigMaps
kubectl get configmap -n tetragon tetragon-stack-policies -o yaml

# Check Tetragon mandate status
kubectl exec -n tetragon daemonset/tetragon-stack-tetragon -c tetragon -- \
  tetra mandate status
```

## Performance Tuning

### Event Rate Limits

For high-volume environments:

```yaml
tetragon:
  exportRateLimit: 100000  # Events per minute
  eventQueueSize: 50000    # Internal queue size
```

### Batching Configuration

Optimize for throughput vs latency:

```yaml
otelAgent:
  config:
    processors:
      batch:
        send_batch_max_size: 5000  # Larger batches
        timeout: 5s                # Longer wait time
```

### Compression

Enable compression to reduce network traffic:

```yaml
otelAgent:
  config:
    exporters:
      otlp/gateway:
        compression: zstd  # 60-80% reduction
```

### Resource Allocation

Scale resources based on cluster size:

```yaml
# For clusters with 100+ nodes
tetragon:
  resources:
    limits:
      cpu: 2000m
      memory: 2Gi

fluentbit:
  resources:
    limits:
      cpu: 500m
      memory: 200Mi

otelAgent:
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
```

## Security Considerations

### Network Policies

Enable NetworkPolicies for defense in depth:

```yaml
networkPolicies:
  enabled: true
```

This restricts:
- Tetragon: Only export to Fluent Bit
- Fluent Bit: Only forward to OTel Agent
- OTel Agent: Only forward to gateway

### RBAC

The chart creates minimal RBAC permissions:
- Tetragon: Read pods, nodes for metadata enrichment
- Fluent Bit: Read pods for Kubernetes metadata
- OTel Agent: No RBAC required

### TLS

Enable TLS for gateway connection:

```yaml
global:
  otelGatewayTLS:
    enabled: true
    insecure: false
    ca_file: /etc/otel/certs/ca.crt
```

## Monitoring

### Prometheus Metrics

Enable ServiceMonitors:

```yaml
monitoring:
  enabled: true
```

**Tetragon Metrics**:
- `tetragon_events_total`: Total events generated
- `tetragon_process_cache_size`: Process cache entries
- `tetragon_bpf_programs_loaded`: Loaded eBPF programs

**OTel Collector Metrics**:
- `otelcol_receiver_accepted_log_records`: Logs received
- `otelcol_exporter_sent_log_records`: Logs forwarded
- `otelcol_processor_batch_batch_send_size`: Batch sizes

### Grafana Dashboards

Import dashboards from:
- Tetragon: https://grafana.com/grafana/dashboards/tetragon
- OTel Collector: https://grafana.com/grafana/dashboards/otel-collector

## Documentation

Complete documentation available at:
- Architecture: [docs/TETRAGON_OTEL_ARCHITECTURE.md](../../docs/TETRAGON_OTEL_ARCHITECTURE.md)
- Complete Guide: [docs/TETRAGON_COMPLETE_GUIDE.md](../../docs/TETRAGON_COMPLETE_GUIDE.md)
- Helm Configuration: [docs/TETRAGON_HELM_CONFIG.md](../../docs/TETRAGON_HELM_CONFIG.md)
- Mandate Files: [docs/TETRAGON_MANDATE_HOWTO.md](../../docs/TETRAGON_MANDATE_HOWTO.md)
- Troubleshooting: [docs/TETRAGON_OTEL_MONITORING.md](../../docs/TETRAGON_OTEL_MONITORING.md)

## Chart Dependencies

This chart depends on:
- [tetragon](https://helm.isovalent.com) - v1.16.0
- [fluent-bit](https://fluent.github.io/helm-charts) - v0.47.10
- [opentelemetry-collector](https://open-telemetry.github.io/opentelemetry-helm-charts) - v0.97.1

## Version Support

| Chart Version | Tetragon Version | Kubernetes Version |
|---------------|------------------|-------------------|
| 0.1.x         | 1.16.x          | 1.21+             |

Each chart version supports a single Tetragon version to ensure compatibility.

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/hypershield-se/merge/issues
- Documentation: https://github.com/hypershield-se/merge/blob/main/docs/
- Tetragon Docs: https://tetragon.io/docs/

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with tests
4. Update documentation as needed

## Changelog

### 0.1.0 (Initial Release)

- Umbrella chart with Tetragon, Fluent Bit, and OTel Collector
- ConfigMap and URL-based mandate support
- Four pre-configured TracingPolicies
- Four deployment examples (minimal, production, high-volume, low-resource)
- Prometheus ServiceMonitor integration
- NetworkPolicy support
- Comprehensive documentation
