# Contributing to Ghost GitOps

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the Ghost GitOps repository.

## How to Contribute

### Reporting Issues

Before creating an issue, please:

1. Check if the issue has already been reported
2. Use the issue templates when available
3. Provide clear steps to reproduce the issue
4. Include relevant system information (Kubernetes version, OS, etc.)

### Submitting Changes

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Add tests if applicable
5. Update documentation as needed
6. Submit a pull request

### Code Standards

- Follow existing code style and patterns
- Add comments for complex logic
- Ensure all YAML is properly formatted
- Test changes in a development environment

### Commit Messages

Use conventional commits format:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `refactor:` for code refactoring
- `test:` for test additions or changes

### Pull Request Process

1. Ensure your branch is up to date with `main`
2. Run tests and validation locally
3. Provide a clear description of changes
4. Link any related issues
5. Request review from maintainers

## Development Setup

### Prerequisites

- Kubernetes cluster (k3s, kind, or cloud)
- kubectl
- kustomize
- ArgoCD (optional)

### Local Development

1. Clone the repository
2. Set up a local Kubernetes cluster
3. Apply the development overlay:
   ```bash
   make apply-dev
   ```

### Testing

Run the validation suite:
```bash
make validate
```

## Questions?

If you have questions about contributing, please open an issue or reach out to the maintainers.
