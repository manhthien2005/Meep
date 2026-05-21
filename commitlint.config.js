/**
 * Commitlint config — Meep
 *
 * Conventional Commits với:
 * - Type prefix English (feat, fix, chore, ...)
 * - Mô tả body tiếng Việt (cho phép unicode, không enforce English case)
 * - Subject ≤ 72 chars
 *
 * Local enforce qua husky `commit-msg` hook.
 * CI enforce qua `.github/workflows/pr-check.yml` job validate-commits.
 */

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Cho phép tiếng Việt trong subject (don't enforce lower-case/sentence-case)
    'subject-case': [0],
    'subject-empty': [2, 'never'],
    'subject-min-length': [2, 'always', 5],
    'subject-max-length': [2, 'always', 72],
    'header-max-length': [2, 'always', 100],

    // Type bắt buộc lowercase English
    'type-empty': [2, 'never'],
    'type-case': [2, 'always', 'lower-case'],
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'chore',
        'refactor',
        'docs',
        'test',
        'style',
        'perf',
        'build',
        'ci',
        'revert',
      ],
    ],

    // Scope (nếu có) bắt buộc lowercase
    'scope-case': [2, 'always', 'lower-case'],

    // Body line dài: cho phép vì tiếng Việt có thể dài
    'body-max-line-length': [1, 'always', 100],

    // Không cho subject kết thúc bằng dấu chấm
    'subject-full-stop': [2, 'never', '.'],
  },

  helpUrl:
    'Xem .cursor/rules/20-stack-conventions.mdc (hoặc .windsurf/rules/20-stack-conventions.md) §Git — Team Workflow để biết format chi tiết.',
};
