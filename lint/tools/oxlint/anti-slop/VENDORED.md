# anti-slop, vendored

Copied from [dmmulroy/anti-slop](https://github.com/dmmulroy/anti-slop) (MIT), commit
`6d538555cb151d4121ed51a27db81890eacf8ae9`, 2026-08-18. The source is
`skills/install-anti-slop/assets/anti-slop/`, which is the tests-and-manifest-free copy
the author distributes for vendoring.

## Why vendored rather than a dependency

The author's explicit instruction, and the right call independently: the package has no
releases and lives outside semver, so pinning a version pins you to something that moves
underneath. Copied, the rules are yours to read and to disagree with.

Custom JS plugins are also the young part of the oxlint toolchain in a way the native
Rust rules are not. That one surface being alpha says nothing about `import`,
`typescript` or `nextjs`.

## Updating

There is no auto-update. Re-copy from upstream and record the new commit here:

```bash
git clone --depth 1 https://github.com/dmmulroy/anti-slop.git /tmp/anti-slop
cp -r /tmp/anti-slop/skills/install-anti-slop/assets/anti-slop/. lint/tools/oxlint/anti-slop/
```

Compare the rules and their diagnostics before replacing: the set grows, and a new rule
can arrive switched off in `oxlint.config.ts` without anyone noticing. After copying,
run `node lint/rule-tests/check.mjs`.

## What is not copied

`package.json`, the `*.test.ts` files and `scripts/`. The plugin is consumed from
`oxlint.config.ts` through `jsPlugins`; it is not built. Coverage that the rules still
bite comes from `lint/rule-tests/`, not from upstream's suite.
