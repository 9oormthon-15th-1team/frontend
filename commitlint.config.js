/** @type {import('@commitlint/types').UserConfig} */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-case': [2, 'always', 'pascal-case'],
    'type-enum': [2, 'always', ['Feat', 'Fix', 'Chore', 'Style', 'Docs', 'Refactor', 'Init', 'Build']],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 100],
  },
};
