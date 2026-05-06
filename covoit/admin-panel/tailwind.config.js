/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // AfriGo Brand Colors
        green: {
          DEFAULT: '#1D9E75',
          light: '#E1F5EE',
          dark: '#0F6E56',
          deep: '#085041',
        },
        prime: {
          DEFAULT: '#EF9F27',
          bg: '#FAEEDA',
          dark: '#854F0B',
        },
        coral: {
          DEFAULT: '#D85A30',
          light: '#FAECE7',
        },
        gray: {
          50: '#F1EFE8',
          100: '#D3D1C7',
          400: '#888780',
          600: '#5F5E5A',
          800: '#444441',
          900: '#2C2C2A',
        },
        dark: {
          900: '#111110',
          800: '#1A1A18',
          700: '#242422',
          600: '#2E2E2C',
          500: '#3A3A38',
        },
      },
      fontFamily: {
        sans: ['Outfit', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        'card': '16px',
        'btn': '12px',
      },
    },
  },
  plugins: [],
}
