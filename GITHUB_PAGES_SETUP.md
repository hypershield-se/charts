# GitHub Pages Setup for Helm Chart Repository

This document explains how to set up and maintain the Helm chart repository hosted on GitHub Pages.

## Initial Setup

### 1. Enable GitHub Pages

1. Go to repository Settings > Pages
2. Under "Source", select "GitHub Actions" as the deployment method
3. Save the configuration

### 2. Repository Permissions

Ensure the following permissions are configured:

- **Workflow permissions**: Settings > Actions > General > Workflow permissions
  - Select "Read and write permissions"
  - Check "Allow GitHub Actions to create and approve pull requests"

### 3. Branch Protection (Optional)

For production repositories, configure branch protection for `main`:

- Settings > Branches > Add branch protection rule
- Branch name pattern: `main`
- Enable "Require status checks to pass before merging"
- Select the `lint-test` check

## How It Works

### Automated Release Process

The release process is fully automated via GitHub Actions:

```
Developer commits to chart directories → Workflow triggers → Lint & Test → Package & Release → Publish to GitHub Pages
```

**Workflow file**: `.github/workflows/release-chart.yml`

### Release Steps

1. **Lint and Test** (`lint-test` job):
   - Checks for chart changes using `chart-testing`
   - Runs `helm lint` on modified charts
   - Creates a Kind cluster for integration testing
   - Validates chart installation (currently skipped - requires OTel Gateway)

2. **Release** (`release` job):
   - Adds required Helm repositories (Isovalent, Fluent, OpenTelemetry)
   - Updates chart dependencies
   - Packages charts using `chart-releaser`
   - Creates GitHub releases with packaged charts
   - Updates `index.yaml` on `gh-pages` branch

3. **Publish** (`publish-pages` job):
   - Deploys updated `gh-pages` branch to GitHub Pages
   - Makes charts available at `https://hypershield-se.github.io/merge`

## Triggering Releases

### Automatic Release

Changes to chart files on the `main` branch automatically trigger a release:

```bash
# Make changes to chart
vim tetragon-observability-stack/Chart.yaml

# Commit and push
git add tetragon-observability-stack/
git commit -m "feat: update chart version to 0.2.0"
git push origin main
```

**Important**: Chart version MUST be incremented in `Chart.yaml` for a new release to be created.

### Manual Release

Trigger a release manually via GitHub Actions:

1. Go to Actions > Release Helm Chart
2. Click "Run workflow"
3. Select branch: `main`
4. Click "Run workflow"

## Versioning

### Semantic Versioning

Charts follow semantic versioning (SemVer):

- **MAJOR.MINOR.PATCH** (e.g., `1.2.3`)
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Version Management

Each chart version is tied to specific dependency versions:

```yaml
# Chart.yaml
version: 0.1.0  # Chart version
appVersion: "1.0.0"  # Application version

dependencies:
  - name: tetragon
    version: "1.16.0"  # Specific Tetragon version
```

**Policy**: Single Tetragon version per chart version (no version ranges).

### Incrementing Versions

Before committing changes:

1. Update `version` in `Chart.yaml`:
   ```yaml
   version: 0.2.0  # Incremented from 0.1.0
   ```

2. Update `appVersion` if application version changed:
   ```yaml
   appVersion: "1.1.0"
   ```

3. Update `CHANGELOG.md` (optional but recommended)

4. Commit and push:
   ```bash
   git add charts/tetragon-observability-stack/Chart.yaml
   git commit -m "chore: bump chart version to 0.2.0"
   git push origin main
   ```

## Using the Chart Repository

### Adding the Repository

Users add the repository with:

```bash
helm repo add hypershield https://hypershield-se.github.io/charts
helm repo update
```

### Installing Charts

```bash
helm install tetragon-stack hypershield/tetragon-observability-stack \
  --namespace tetragon \
  --create-namespace
```

### Searching Available Versions

```bash
helm search repo hypershield -l
```

## Chart Repository Structure

After releases, the `gh-pages` branch contains:

```
gh-pages/
├── index.yaml                                    # Chart repository index
├── tetragon-observability-stack-0.1.0.tgz       # Packaged chart
├── tetragon-observability-stack-0.2.0.tgz
└── ...
```

## Troubleshooting

### Release Not Created

**Problem**: Chart changes pushed, but no release created.

**Solutions**:
1. Verify chart version was incremented in `Chart.yaml`
2. Check workflow run: Actions > Release Helm Chart
3. Review workflow logs for errors
4. Ensure `charts/**` path was modified in commit

### Workflow Failures

**Lint failures**:
```bash
# Test locally before pushing
helm lint charts/tetragon-observability-stack/
```

**Dependency issues**:
```bash
# Update dependencies locally
helm dependency update charts/tetragon-observability-stack/
```

**Permission errors**:
- Verify workflow permissions (Settings > Actions > General)
- Ensure `GITHUB_TOKEN` has write access

### Chart Not Available

**Problem**: Chart released but not available via `helm repo add`.

**Solutions**:
1. Verify GitHub Pages is enabled: Settings > Pages
2. Check Pages deployment: Actions > pages-build-deployment
3. Verify `index.yaml` exists on `gh-pages` branch
4. Wait 5-10 minutes for DNS propagation
5. Clear Helm cache: `helm repo update`

### Version Conflicts

**Problem**: Chart version already exists.

**Solutions**:
- Chart-releaser skips existing versions by default
- Increment version in `Chart.yaml` to create new release
- Delete existing release manually: Releases > Delete release (not recommended)

## Manual Operations

### Manual Chart Packaging

For testing or local development:

```bash
# Update dependencies
helm dependency update tetragon-observability-stack/

# Package chart
helm package tetragon-observability-stack/ -d /tmp/charts

# Generate index
helm repo index /tmp/charts --url https://hypershield-se.github.io/charts

# Inspect package
tar -tzf /tmp/charts/tetragon-observability-stack-*.tgz
```

### Manual Release

If automation fails, release manually:

```bash
# Install chart-releaser
go install github.com/helm/chart-releaser@latest

# Package and release
cr package tetragon-observability-stack/
cr upload -o hypershield-se -r charts -p .cr-release-packages
cr index -o hypershield-se -r charts -c https://hypershield-se.github.io/charts -i index.yaml
```

## Best Practices

### 1. Test Before Release

```bash
# Lint chart
helm lint tetragon-observability-stack/

# Template chart (dry-run)
helm template test tetragon-observability-stack/ \
  --set global.otelGatewayEndpoint=test:4317

# Install in test cluster
kind create cluster --name test
helm install tetragon-test tetragon-observability-stack/ \
  --namespace tetragon \
  --create-namespace \
  --set global.otelGatewayEndpoint=test:4317 \
  --dry-run
```

### 2. Version Increments

- **Patch** (0.1.0 → 0.1.1): Bug fixes, documentation updates
- **Minor** (0.1.0 → 0.2.0): New features, new policies, configuration options
- **Major** (0.1.0 → 1.0.0): Breaking changes, dependency major version bumps

### 3. Changelog

Maintain a CHANGELOG.md in the chart directory:

```markdown
# Changelog

## [0.2.0] - 2025-01-15
### Added
- HTTP monitoring policy
- TLS monitoring policy

### Changed
- Updated Tetragon to 1.17.0

### Fixed
- Resource limits for Fluent Bit
```

### 4. Testing in Production

Use version constraints for safer upgrades:

```bash
# Install specific version
helm install tetragon-stack tetragon-observability/tetragon-observability-stack \
  --version 0.1.0

# Upgrade with version constraint
helm upgrade tetragon-stack tetragon-observability/tetragon-observability-stack \
  --version "~0.1.0"  # Only patch updates (0.1.x)
```

## Security Considerations

### Chart Signing (Future Enhancement)

To enable chart signing:

1. Generate GPG key:
   ```bash
   gpg --full-generate-key
   ```

2. Add GPG key to GitHub Secrets:
   - Settings > Secrets > Actions > New repository secret
   - Name: `GPG_PRIVATE_KEY`
   - Value: `gpg --armor --export-secret-key <key-id>`

3. Update workflow to sign packages:
   ```yaml
   - name: Run chart-releaser
     env:
       CR_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
       CR_KEY: "${{ secrets.GPG_PRIVATE_KEY }}"
     with:
       sign: true
   ```

### Provenance

Chart-releaser automatically generates provenance files for each release.

## Monitoring

### GitHub Actions Status

Monitor workflow runs:
- Actions tab: https://github.com/hypershield-se/merge/actions
- Subscribe to workflow notifications: Repository > Watch > Custom > Actions

### Chart Downloads

Track chart usage via GitHub releases:
- Releases > View release > Download statistics

## References

- [Chart Releaser Action](https://github.com/helm/chart-releaser-action)
- [Chart Testing](https://github.com/helm/chart-testing)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Semantic Versioning](https://semver.org/)
