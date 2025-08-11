# Contributing to System Restore Toolkit

Thank you for your interest in contributing to the System Restore Toolkit! This document provides guidelines and information for contributors.

## 🚀 Quick Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/ppmatrix/system-restore-toolkit.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test thoroughly (both native and Docker)
6. Submit a pull request

## 🛠️ Development Setup

### Native Development
```bash
# Clone and setup
git clone https://github.com/ppmatrix/system-restore-toolkit.git
cd system-restore-toolkit

# Test installation
./install.sh --check

# Test main functionality
./system-restore-toolkit help
./system-restore-toolkit disk-usage
```

### Docker Development
```bash
# Build and test Docker image
./system-restore-toolkit docker-build
docker run --rm system-restore-toolkit help

# Or use docker-compose
docker-compose build
docker-compose up -d
```

## 🧪 Testing

Before submitting a PR, please ensure:

- [ ] Native installation works: `./install.sh --check`
- [ ] Docker build succeeds: `docker build -t test .`
- [ ] Main commands work: `./system-restore-toolkit help`, `disk-usage`
- [ ] Scripts are executable and have proper shebangs
- [ ] Code follows existing style and patterns

## 📝 Code Style

- Use `#!/bin/bash` for shell scripts
- Follow existing error handling patterns from `lib/common.sh`
- Add proper logging with `log_info`, `log_error`, etc.
- Include help text for new commands
- Update README.md for new features

## 🎯 Areas for Contribution

### High Priority
- Additional backup strategies (BTRFS, ZFS snapshots)
- Cloud storage integration (AWS S3, Google Cloud, etc.)
- Web interface for management
- Automated scheduling and retention policies

### Medium Priority
- Support for other Linux distributions
- Integration with monitoring systems
- Performance optimizations
- Additional restore methods

### Documentation
- Video tutorials
- Use case examples
- Troubleshooting guides
- Translation to other languages

## 📋 Pull Request Process

1. **Create Issue First** - For major changes, create an issue to discuss
2. **Branch Naming** - Use descriptive names: `feature/web-interface`, `fix/docker-path-issue`
3. **Commit Messages** - Follow conventional commit format:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `test:` for testing improvements
4. **Testing** - Ensure all tests pass and add new tests for new functionality
5. **Documentation** - Update relevant documentation

## 🐛 Bug Reports

When reporting bugs, please include:

- **System Information**: OS, version, LVM setup
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Logs**: Relevant log files from `/var/log/system-restore-toolkit/`
- **Docker Environment**: If using Docker, include container logs

## 💡 Feature Requests

For feature requests, please provide:

- **Use Case**: Why is this feature needed?
- **Proposed Solution**: How would you like it to work?
- **Alternatives**: Have you considered alternative solutions?
- **Additional Context**: Any other relevant information

## 🏷️ Release Process

Releases follow semantic versioning (SemVer):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

## 📚 Resources

- [Docker Documentation](https://docs.docker.com/)
- [LVM Administration Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/logical_volume_manager_administration/index)
- [Bash Style Guide](https://google.github.io/styleguide/shellguide.html)

## 📞 Getting Help

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Check existing documentation in the repository

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to make system backup and restore more reliable for everyone!** 🙏
