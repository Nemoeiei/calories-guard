/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#f2f7ec',
          100: '#E8EFCF',
          200: '#d4e3ae',
          300: '#AFD198',
          400: '#8ab97a',
          500: '#628141',
          600: '#507034',
          700: '#3e5828',
          800: '#2D4A1C',
          900: '#1e3212',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
