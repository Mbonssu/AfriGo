import { createContext, useContext, useState, useEffect } from 'react'

const ThemeContext = createContext()

export function ThemeProvider({ children }) {
  const [isDark, setIsDark] = useState(() => {
    // Check localStorage first
    const saved = localStorage.getItem('admin_theme')
    console.log('Initial theme from localStorage:', saved)
    if (saved) {
      return saved === 'dark'
    }
    // Check system preference
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    console.log('System prefers dark mode:', prefersDark)
    return prefersDark
  })

  useEffect(() => {
    const root = document.documentElement
    console.log('Theme changed to:', isDark ? 'dark' : 'light')
    
    if (isDark) {
      root.classList.add('dark')
      localStorage.setItem('admin_theme', 'dark')
      console.log('Dark mode applied, classList:', root.classList.toString())
    } else {
      root.classList.remove('dark')
      localStorage.setItem('admin_theme', 'light')
      console.log('Light mode applied, classList:', root.classList.toString())
    }
  }, [isDark])

  const toggleTheme = () => {
    console.log('Toggle theme called, current isDark:', isDark)
    setIsDark(prev => {
      const newValue = !prev
      console.log('New isDark value:', newValue)
      return newValue
    })
  }

  return (
    <ThemeContext.Provider value={{ isDark, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider')
  }
  return context
}
