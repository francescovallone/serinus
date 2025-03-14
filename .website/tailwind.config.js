/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['components/**/*.vue', './**/*.md', '.vitepress/theme/*.vue', '!./**/node_modules/**/*.md'],
  theme: {
    extend: {
      minHeight: {
        '128': '32rem',
        '144': '36rem',
        '160': '40rem',
        '192': '48rem',
      }
    },
  },
  plugins: [],
}

