# Installation

`gh dashboard` is a [GitHub CLI](https://cli.github.com) extension written in
bash. It needs:

| Tool | Why | macOS | Windows | Linux |
|---|---|---|---|---|
| [`gh`](https://cli.github.com) | Talks to the GitHub API | install | install | install |
| [`jq`](https://jqlang.org) | Processes the API's JSON | install | install | install |
| `git` | Finds the repository you're in | included | with Git for Windows | usually included |
| `bash` 3.2+ | Runs the extension | included | with Git for Windows (Git Bash) | included |
| `perl` | Measures column widths | included | with Git for Windows | usually included |

- [macOS](#macos)
- [Windows](#windows)
- [Linux](#linux)
- [WSL](#wsl-windows-subsystem-for-linux)
- [Without the extension system](#without-the-extension-system)
- [Verify the install](#verify-the-install)
- [Upgrade](#upgrade)
- [Pin a version](#pin-a-version)
- [Uninstall](#uninstall)
- [Several GitHub accounts](#several-github-accounts)

## macOS

1. Install the tools with [Homebrew](https://brew.sh):

   ```bash
   brew install gh jq
   ```

2. Log in to GitHub:

   ```bash
   gh auth login
   ```

3. Install the extension:

   ```bash
   gh extension install BenSagir/gh-dashboard
   ```

macOS's built-in `/bin/bash` (3.2) is enough, so you don't need a newer bash.

## Windows

The extension runs in **Git Bash**, which comes with Git for Windows. You
start it from any terminal: `gh` launches Git Bash behind the scenes.

1. Install Git for Windows, the GitHub CLI and jq. In PowerShell:

   ```powershell
   winget install Git.Git GitHub.cli jqlang.jq
   ```

   Then **close and reopen your terminal** so the new commands are on your
   `PATH`.

   <details>
   <summary>Without winget</summary>

   - Git for Windows: https://git-scm.com/download/win
   - GitHub CLI: https://cli.github.com
   - jq: `choco install jq` or `scoop install jq`, or download `jq.exe` from
     https://jqlang.org/download/ into a folder on your `PATH`.

   </details>

2. Log in to GitHub:

   ```powershell
   gh auth login
   ```

3. Install the extension:

   ```powershell
   gh extension install BenSagir/gh-dashboard
   ```

4. Use **Windows Terminal**, the default terminal on Windows 11 (Microsoft
   Store on Windows 10). The legacy console window can't show the colors,
   symbols (✓ ◷ ✗ 💬) or clickable links.

Notes:

- The extension works from PowerShell, cmd and Git Bash alike.
- `jq.exe` writes Windows line endings (`\r\n`). The extension detects Git
  Bash and strips them, so you don't need to configure anything.
- The repository forces Unix line endings for its files (`.gitattributes`),
  so a global `core.autocrlf=true` setting doesn't break the script.

## Linux

1. Install the GitHub CLI by following
   [its Linux instructions](https://github.com/cli/cli/blob/trunk/docs/install_linux.md),
   and jq from your package manager:

   ```bash
   sudo apt install jq        # Debian / Ubuntu
   sudo dnf install jq        # Fedora / RHEL
   sudo pacman -S jq          # Arch
   ```

2. Log in and install:

   ```bash
   gh auth login
   gh extension install BenSagir/gh-dashboard
   ```

## WSL (Windows Subsystem for Linux)

Follow the [Linux](#linux) steps inside your WSL distribution. Run the
dashboard from repositories cloned inside WSL. A Windows-side `gh` login
isn't shared with WSL, so run `gh auth login` there too.

## Without the extension system

The extension is a single bash script, so you can also put it on your `PATH`
directly and run it as `gh-dashboard`:

```bash
curl -fsSL https://raw.githubusercontent.com/BenSagir/gh-dashboard/main/gh-dashboard \
  -o ~/.local/bin/gh-dashboard
chmod +x ~/.local/bin/gh-dashboard
```

Make sure `~/.local/bin` is on your `PATH`. You still need `gh`, `jq`, `git`
and `perl`. Updates are manual: run the `curl` command again.

## Verify the install

```bash
gh dashboard --version
```

Then, inside any clone of a GitHub repository:

```bash
gh dashboard
```

If it prints an error, see [troubleshooting](troubleshooting.md).

## Upgrade

```bash
gh extension upgrade dashboard
```

or upgrade all your extensions with `gh extension upgrade --all`.

## Pin a version

To stay on a specific release instead of the latest commit:

```bash
gh extension install BenSagir/gh-dashboard --pin v1.0.0
```

Pinned extensions are skipped by `gh extension upgrade`. To unpin, remove the
extension and install it again without `--pin`.

## Uninstall

```bash
gh extension remove dashboard
```

If you installed it [without the extension system](#without-the-extension-system),
delete the `gh-dashboard` file you downloaded.

## Several GitHub accounts

If you use separate accounts, for example work and personal, log in to each
one:

```bash
gh auth login        # first account
gh auth login        # again, choosing the second account
gh auth status       # shows both; one is "Active"
```

You don't need to switch between them for the dashboard. When the active
account can't see a repository, the dashboard tries your other logged-in
accounts and uses the first one that can, for that run only. Your active
account doesn't change. See [how it works](how-it-works.md#repository-and-account-detection).
