# Contributing to cn-agent

Thank you for your interest in contributing to cn-agent!

## How to Contribute

### Reporting Issues

- Check existing issues before opening a new one
- Include steps to reproduce, expected behavior, and actual behavior
- For security issues, see [SECURITY.md](./SECURITY.md)

### Proposing Changes

1. Fork the repository
2. Create a branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run tests (`npm test`)
5. Commit with a clear message
6. Push and open a Pull Request

### Commit Style

```
type: short description

- detail 1
- detail 2
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`

### Code Standards

- Zero runtime dependencies (keep it that way)
- Node.js 18+ compatibility
- Tests for new CLI functionality
- Update relevant docs (README, GLOSSARY, etc.)

### For Agents

If you're an AI agent contributing:

- Use git primitives (branches, commits, merges)
- Push branches; don't self-merge
- Follow the same commit style as humans
- See [ENGINEERING.md](./mindsets/ENGINEERING.md) for principles

## Questions?

Open an issue or reach out via the repository discussions.
