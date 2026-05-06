import { Link, useLocation } from 'react-router-dom'
import { 
  LayoutDashboard, 
  Users, 
  Car, 
  Route as RouteIcon, 
  CreditCard, 
  Settings,
  LogOut,
  Menu,
  X
} from 'lucide-react'
import { useState } from 'react'

const navigation = [
  { name: 'Tableau de bord', href: '/', icon: LayoutDashboard },
  { name: 'Utilisateurs', href: '/users', icon: Users },
  { name: 'Chauffeurs', href: '/drivers', icon: Car },
  { name: 'Trajets', href: '/trips', icon: RouteIcon },
  { name: 'Réservations', href: '/bookings', icon: CreditCard },
  { name: 'Paiements', href: '/payments', icon: CreditCard },
  { name: 'Paramètres', href: '/settings', icon: Settings },
]

export default function Layout({ children, onLogout }) {
  const location = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  return (
    <div className="min-h-screen flex">
      {/* Sidebar Desktop */}
      <aside className="hidden lg:flex lg:flex-col lg:w-64 bg-white border-r border-gray-100/30">
        <div className="flex items-center gap-3 px-6 py-5 border-b border-gray-100/30">
          <div className="w-10 h-10 bg-green rounded-xl flex items-center justify-center">
            <span className="text-white font-bold text-lg">A</span>
          </div>
          <div>
            <h1 className="font-bold text-lg text-gray-900">AfriGo</h1>
            <p className="text-xs text-gray-600">Administration</p>
          </div>
        </div>

        <nav className="flex-1 px-3 py-4 space-y-1">
          {navigation.map((item) => {
            const isActive = location.pathname === item.href
            return (
              <Link
                key={item.name}
                to={item.href}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-btn text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-green-light text-green'
                    : 'text-gray-600 hover:bg-gray-50'
                }`}
              >
                <item.icon className="w-5 h-5" />
                {item.name}
              </Link>
            )
          })}
        </nav>

        <div className="p-3 border-t border-gray-100/30">
          <button
            onClick={onLogout}
            className="flex items-center gap-3 w-full px-3 py-2.5 rounded-btn text-sm font-medium text-coral hover:bg-coral-light transition-colors"
          >
            <LogOut className="w-5 h-5" />
            Déconnexion
          </button>
        </div>
      </aside>

      {/* Sidebar Mobile */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="fixed inset-0 bg-gray-900/50" onClick={() => setSidebarOpen(false)} />
          <aside className="fixed inset-y-0 left-0 w-64 bg-white">
            <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100/30">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-green rounded-xl flex items-center justify-center">
                  <span className="text-white font-bold text-lg">A</span>
                </div>
                <div>
                  <h1 className="font-bold text-lg text-gray-900">AfriGo</h1>
                  <p className="text-xs text-gray-600">Administration</p>
                </div>
              </div>
              <button onClick={() => setSidebarOpen(false)}>
                <X className="w-6 h-6 text-gray-600" />
              </button>
            </div>

            <nav className="px-3 py-4 space-y-1">
              {navigation.map((item) => {
                const isActive = location.pathname === item.href
                return (
                  <Link
                    key={item.name}
                    to={item.href}
                    onClick={() => setSidebarOpen(false)}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-btn text-sm font-medium transition-colors ${
                      isActive
                        ? 'bg-green-light text-green'
                        : 'text-gray-600 hover:bg-gray-50'
                    }`}
                  >
                    <item.icon className="w-5 h-5" />
                    {item.name}
                  </Link>
                )
              })}
            </nav>

            <div className="absolute bottom-0 left-0 right-0 p-3 border-t border-gray-100/30">
              <button
                onClick={onLogout}
                className="flex items-center gap-3 w-full px-3 py-2.5 rounded-btn text-sm font-medium text-coral hover:bg-coral-light transition-colors"
              >
                <LogOut className="w-5 h-5" />
                Déconnexion
              </button>
            </div>
          </aside>
        </div>
      )}

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Header */}
        <header className="bg-white border-b border-gray-100/30 px-4 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <button
              onClick={() => setSidebarOpen(true)}
              className="lg:hidden p-2 rounded-btn hover:bg-gray-50"
            >
              <Menu className="w-6 h-6 text-gray-600" />
            </button>
            <div className="flex-1 lg:flex-none">
              <h2 className="text-xl font-bold text-gray-900">
                {navigation.find(item => item.href === location.pathname)?.name || 'AfriGo Admin'}
              </h2>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-auto p-4 lg:p-8">
          {children}
        </main>
      </div>
    </div>
  )
}
