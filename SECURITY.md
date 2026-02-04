# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.4.x   | :white_check_mark: |
| < 1.4   | :x:                |

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Instead, please report security issues by emailing the maintainers directly or using GitHub's private vulnerability reporting feature.

Include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes (optional)

## Response Timeline

- **Acknowledgment:** Within 48 hours
- **Initial assessment:** Within 1 week
- **Resolution target:** Depends on severity

## Security Considerations

cn-agent is a CLI tool that:

- Executes shell commands (`git`, `gh`)
- Creates files and directories
- Interacts with GitHub API

When using cn-agent:

- Review the CLI source code before running
- Use in trusted environments
- Keep your GitHub credentials secure
- Don't expose API tokens in commits

## Agent-Specific Security

For AI agents using cn-agent:

- Agents should not store credentials in hub repos
- Use environment variables or secure credential storage
- Review agent commits before merging to shared repos
