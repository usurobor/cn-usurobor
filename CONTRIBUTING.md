# Contributing to cnos

## How to Contribute

### Reporting Issues

GitHub Issues is the single source of truth for bugs, features, and backlog.

- Check existing issues before opening a new one
- Include steps to reproduce, expected behavior, and actual behavior
- For security issues, see [SECURITY.md](./SECURITY.md)

### Proposing Changes

1. Fork the repository
2. Create a branch from `main`
3. Make your changes
4. Run tests (`dune runtest`)
5. Commit with a clear message
6. Push and open a Pull Request

### Commit Style

```
type: short description

- detail 1
- detail 2
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `MCI`, `MCA`

### Code Standards

- Native OCaml only — no JavaScript, no Melange
- Zero runtime dependencies
- Tests for new functionality
- Update relevant docs

### Development Method

cnos uses coherence-driven development (CDD). See [docs/γ/CDD.md](./docs/γ/CDD.md) for the full method and [docs/γ/RULES.md](./docs/γ/RULES.md) for non-negotiable rules.

### For Agents

- Use git primitives (branches, commits, merges)
- Push branches; don't self-merge
- Follow the same commit style as humans
- Doctrine and skills live in `src/agent/`, packages are built from there via `cn build`

## Questions?

Open an issue on GitHub.
