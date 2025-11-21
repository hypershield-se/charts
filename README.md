# HyperShield Helm Charts

Unofficial Helm chart repository for HyperShield related charts. 

## Usage

Add this repository to Helm:

```bash
helm repo add hypershield https://hypershield-se.github.io/charts
helm repo update
```

## Available Charts

### Tetragon Observability Stack

Complete observability stack for Cilium Tetragon with Fluent Bit and OpenTelemetry Collector.

**Install:**

```bash
helm install tetragon-stack hypershield/tetragon-observability-stack \
  --namespace tetragon \
  --create-namespace \
  --set global.clusterName="my-cluster" \
  --set global.otelGatewayEndpoint="otel-gateway.monitoring.svc:4317"
```

**Documentation:**
- [Chart README](tetragon-observability-stack/README.md)
- [Values Examples](tetragon-observability-stack/values-examples/)
- [Changelog](tetragon-observability-stack/CHANGELOG.md)

**Features:**
- eBPF-based runtime security observability with Tetragon
- Lightweight log collection with Fluent Bit
- OpenTelemetry Collector for telemetry processing
- Flexible policy management (ConfigMap or URL-based)
- Production-grade telemetry pipeline with compression and retry
- Prometheus ServiceMonitors for monitoring
- NetworkPolicies for security
- Four deployment scenarios (minimal, production, high-volume, low-resource)

**Quick Start:**

```bash
# Minimal deployment (development/testing)
helm install tetragon-stack hypershield/tetragon-observability-stack \
  --values https://raw.githubusercontent.com/hypershield-se/charts/main/tetragon-observability-stack/values-examples/minimal.yaml \
  --set global.otelGatewayEndpoint="otel-gateway.default.svc:4317" \
  --set fluentbit.env[2].value="tetragon-stack-otelAgent"

# Production deployment
helm install tetragon-stack hypershield/tetragon-observability-stack \
  --values https://raw.githubusercontent.com/hypershield-se/charts/main/tetragon-observability-stack/values-examples/production.yaml \
  --set global.otelGatewayEndpoint="otel-gateway.monitoring.svc:4317" \
  --set fluentbit.env[2].value="tetragon-stack-otelAgent"
```

## Chart Versions

| Chart Version | App Version | Tetragon Version | Kubernetes Version |
|---------------|-------------|------------------|-------------------|
| 0.1.x         | 1.0.0       | 1.16.x          | 1.21+             |

## Development

### Prerequisites

- Helm 3.8+
- Kubernetes 1.21+ (for testing)

### Testing Charts Locally

```bash
# Clone repository
git clone https://github.com/hypershield-se/charts.git
cd charts

# Update dependencies
helm dependency update tetragon-observability-stack/

# Lint chart
helm lint tetragon-observability-stack/

# Template chart
helm template test tetragon-observability-stack/ \
  --values tetragon-observability-stack/values-examples/minimal.yaml

# Install from local directory
helm install tetragon-stack ./tetragon-observability-stack \
  --namespace tetragon \
  --create-namespace \
  --values tetragon-observability-stack/values-examples/minimal.yaml \
  --set global.otelGatewayEndpoint="otel-gateway.default.svc:4317" \
  --set fluentbit.env[2].value="tetragon-stack-otelAgent"
```

### Chart Structure

```
charts/
├── .github/
│   ├── workflows/
│   │   └── release-chart.yml    # Automated chart release
│   ├── cr.yaml                   # Chart releaser config
│   └── ct.yaml                   # Chart testing config
├── tetragon-observability-stack/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── README.md
│   ├── CHANGELOG.md
│   ├── LICENSE
│   ├── templates/
│   │   ├── _helpers.tpl
│   │   ├── NOTES.txt
│   │   ├── configmap-mandate.yaml
│   │   ├── configmap-policies.yaml
│   │   ├── deployment-policy-server.yaml
│   │   ├── servicemonitor-*.yaml
│   │   └── networkpolicy-*.yaml
│   └── values-examples/
│       ├── minimal.yaml
│       ├── production.yaml
│       ├── high-volume.yaml
│       └── low-resource.yaml
├── README.md
└── GITHUB_PAGES_SETUP.md
```

### Release Process

Charts are automatically released when changes are pushed to the `main` branch:

1. Update chart version in `Chart.yaml`
2. Update `CHANGELOG.md` with changes
3. Commit and push to `main`
4. GitHub Actions automatically:
   - Lints the chart
   - Packages the chart
   - Creates a GitHub release
   - Updates the Helm repository index
   - Deploys to GitHub Pages

**Manual Release:**

```bash
# Package chart
helm package tetragon-observability-stack/

# Generate/update index
helm repo index . --url https://hypershield-se.github.io/charts

# Commit and push
git add .
git commit -m "Release tetragon-observability-stack-0.1.0"
git push origin main
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Update chart version in `Chart.yaml`
5. Update `CHANGELOG.md`
6. Test locally
7. Submit a pull request

### Contribution Guidelines

- Follow [Helm chart best practices](https://helm.sh/docs/chart_best_practices/)
- Use semantic versioning for chart versions
- Update documentation with any configuration changes
- Test with all example values files
- Add entries to CHANGELOG.md

## Support

- **Issues**: [GitHub Issues](https://github.com/hypershield-se/charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/hypershield-se/charts/discussions)
- **Documentation**: See individual chart READMEs

## License

Apache 2.0 - See [LICENSE](tetragon-observability-stack/LICENSE) for details.

## Related Projects

- [Cilium Tetragon](https://github.com/cilium/tetragon) - eBPF-based Security Observability
- [Fluent Bit](https://github.com/fluent/fluent-bit) - Fast and Lightweight Log Processor
- [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) - Vendor-agnostic telemetry collection

## Acknowledgments

This chart integrates several open-source projects:
- Tetragon by Isovalent/Cilium
- Fluent Bit by the Fluent community
- OpenTelemetry Collector by the OpenTelemetry project
