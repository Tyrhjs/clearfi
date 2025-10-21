/** @type {import('eslint').Linter.Config} */
module.exports = {
  root: false,
  extends: ['next/core-web-vitals', 'eslint:recommended'],
  parserOptions: { ecmaVersion: 2022, sourceType: 'module' },
  rules: {
    'no-console': ['warn', { allow: ['warn', 'error'] }]
  }
};
