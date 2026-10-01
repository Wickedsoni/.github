# Contributing

Thanks for helping out. A few things make reviews quick:

1. **Open an issue first** for anything bigger than a small fix, so we agree on the approach before you write code.
2. **Branch from `main`** and keep each PR to one change.
3. **Title the PR with a Conventional Commit**, like `feat(scan): show channel width` or `fix: crash on empty floor plan`. A check enforces this, and it decides how the change appears in release notes.
4. **Run the checks locally** before pushing:
   - Android / Kotlin: `./gradlew lintDebug testDebugUnitTest`
   - Web / Node: `npm run lint && npm test`
5. **Add or update tests** for logic changes, and screenshots for UI changes.

By contributing you agree your work is released under the repository's license.
