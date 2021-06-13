const colors = require('tailwindcss/colors')

module.exports = {
  mode: 'jit',
  purge: {
    enabled: true,
    content: [
    './build/*.html'
    ]
  },
  darkMode: 'media', // or 'media' or 'class'
  theme: {
    extend: {
      colors: {
        'light-blue': colors.lightBlue,
        cyan: colors.cyan,
      },      
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
