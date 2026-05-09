# Use Mini.test for screen assertions

Precognition's most important behavior is whether Hints appear in the right place on screen, so tests need to verify rendered Hint placement rather than only inspecting internal extmark data. We use `mini.test` as the sole test harness because it supports Neovim-focused tests and screen assertions, which prepares the project to revisit wrapped-line Hint behavior in issue #41 and draft PR #74.

We considered keeping Plenary/Busted, but that would keep the suite centered on internal-state assertions. Mini.test runs across the supported CI operating systems with one shared screen baseline by default; explicit per-OS baselines should only be introduced if a platform-specific rendering difference is proven unavoidable and acceptable.
