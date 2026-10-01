<img src="https://raw.githubusercontent.com/Wickedsoni/Wickedsoni/main/assets/ping/ping-code.svg" alt="Ping, my mascot, typing" width="130" align="right">

# Shared GitHub setup

[![Self-test](https://github.com/Wickedsoni/.github/actions/workflows/self-test.yml/badge.svg)](https://github.com/Wickedsoni/.github/actions/workflows/self-test.yml)

CI/CD and repo defaults for every project under [@Wickedsoni](https://github.com/Wickedsoni). Workflows live here once,
and each project calls them in a few lines, so fixing or upgrading one fixes every repo that uses it.

## Start a new project

```bash
cd my-new-project            # must already be a git repo with a GitHub remote
curl -fsSL https://raw.githubusercontent.com/Wickedsoni/.github/main/bootstrap.sh | bash -s -- android   # or kobweb, node
```

That copies the [starter workflows](starters/) without overwriting anything, then uses `gh` to set the repo up:
squash merges titled from the PR, auto-merge, delete-branch-on-merge, Dependabot alerts and security fixes, and private
vulnerability reporting.

## What each project gets

| | Android | Kobweb site | Node / JS |
|---|:-:|:-:|:-:|
| Build, lint and unit tests on every push and PR | ✅ | – | ✅ |
| CodeQL security scan | ✅ | – | ✅ |
| Signed APK + AAB attached to a GitHub Release on `v*` tags | ✅ | – | – |
| Production deploy on `main`, preview deploy on PRs (Vercel) | – | ✅ | – |
| Dependabot updates, grouped so you get a few PRs instead of dozens | ✅ | ✅ | ✅ |
| PR title check, size and type labels, dependency review | ✅ | ✅ | ✅ |
| Release notes drafted automatically from merged PRs | ✅ | ✅ | ✅ |
| Stale issue and PR cleanup | ✅ | ✅ | ✅ |

## Reusable workflows

| Workflow | What it does | Main inputs |
|---|---|---|
| [`android-ci.yml`](.github/workflows/android-ci.yml) | Gradle build with caching, uploads test/lint reports and the debug APK | `tasks`, `java-version`, `working-directory` |
| [`android-release.yml`](.github/workflows/android-release.yml) | Release APK + AAB (+ R8 mapping), signed if keystore secrets exist, published to GitHub Releases | `tasks`, `prerelease` |
| [`kobweb-vercel.yml`](.github/workflows/kobweb-vercel.yml) | `kobweb export` then `vercel deploy`, prod or preview, URL in the run summary | `site-dir`, `production`, `extra-files` |
| [`node-ci.yml`](.github/workflows/node-ci.yml) | Detects npm / pnpm / yarn / bun, runs whichever of `lint typecheck test build` exist | `node-version`, `scripts` |
| [`codeql.yml`](.github/workflows/codeql.yml) | CodeQL `security-and-quality` queries | `languages` (JSON) |
| [`pr-checks.yml`](.github/workflows/pr-checks.yml) | Conventional-commit PR titles, `size/*` and type labels, dependency review | `dependency-review` |
| [`release-drafter.yml`](.github/workflows/release-drafter.yml) | Keeps a draft release with grouped notes and the next semver | – |
| [`stale.yml`](.github/workflows/stale.yml) | Marks inactive issues/PRs stale, then closes them | `days-before-stale`, `days-before-close` |

Call one from any repo:

```yaml
jobs:
  ci:
    uses: Wickedsoni/.github/.github/workflows/android-ci.yml@main
    with:
      tasks: "assembleDebug lintDebug testDebugUnitTest"
```

## Release flow

1. Merge PRs titled `feat: ...`, `fix: ...`, and so on. Release Drafter keeps a draft release up to date. `feat` bumps
   the minor version, `feat!:` (breaking) bumps the major, and everything else bumps the patch.
2. When you're ready, open **Releases**, check the draft, and click **Publish**. That creates the `vX.Y.Z` tag.
3. For Android repos, the tag triggers `android-release.yml`, which attaches the APK and AAB to that release.

### Signing Android releases

Add four repo secrets: `ANDROID_KEYSTORE_BASE64` (output of `base64 -w0 release.jks`), `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`. Then read them in `app/build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            System.getenv("ANDROID_KEYSTORE_PATH")?.let { path ->
                storeFile = file(path)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            if (System.getenv("ANDROID_KEYSTORE_PATH") != null) signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

Without the secrets the build still runs and produces unsigned artifacts.

## Defaults for every repo

GitHub uses these files for any of my repos that doesn't have its own copy:
[bug report and feature request forms](.github/ISSUE_TEMPLATE/), a [PR template](.github/PULL_REQUEST_TEMPLATE.md),
[CONTRIBUTING](CONTRIBUTING.md) and a [security policy](SECURITY.md).

## Maintenance

- Dependabot bumps the action versions used here once a month. The [self-test](.github/workflows/self-test.yml) workflow
  lints every workflow with actionlint and runs Node CI, Android CI (against WifiLens) and CodeQL whenever they change.
- Callers use `@main`. To freeze a project on a known-good version, tag this repo (for example `v1`) and call `@v1` instead.
