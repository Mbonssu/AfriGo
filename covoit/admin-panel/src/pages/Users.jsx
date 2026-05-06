import { useState } from 'react'
import { Search, Filter, UserPlus, MoreVertical, Mail, Phone, Calendar } from 'lucide-react'

// Données simulées
const mockUsers = [
  { id: 1, name: 'Jean Kamga', email: 'jean.kamga@email.com', phone: '+237 690 123 456', role: 'driver', status: 'active', joined: '2024-01-15', trips: 45 },
  { id: 2, name: 'Marie Ngo', email: 'marie.ngo@email.com', phone: '+237 677 234 567', role: 'passenger', status: 'active', joined: '2024-02-20', trips: 12 },
  { id: 3, name: 'Paul Mbida', email: 'paul.mbida@email.com', phone: '+237 655 345 678', role: 'driver', status: 'active', joined: '2024-01-10', trips: 67 },
  { id: 4, name: 'Sophie Talla', email: 'sophie.talla@email.com', phone: '+237 698 456 789', role: 'passenger', status: 'suspended', joined: '2024-03-05', trips: 8 },
  { id: 5, name: 'Eric Fouda', email: 'eric.fouda@email.com', phone: '+237 670 567 890', role: 'driver', status: 'active', joined: '2023-12-01', trips: 123 },
]

export default function Users() {
  const [searchTerm, setSearchTerm] = useState('')
  const [filterRole, setFilterRole] = useState('all')
  const [filterStatus, setFilterStatus] = useState('all')

  const filteredUsers = mockUsers.filter(user => {
    const matchesSearch = user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesRole = filterRole === 'all' || user.role === filterRole
    const matchesStatus = filterStatus === 'all' || user.status === filterStatus
    return matchesSearch && matchesRole && matchesStatus
  })

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Utilisateurs</h1>
          <p className="text-gray-600 mt-1">{mockUsers.length} utilisateurs au total</p>
        </div>
        <button className="btn-primary flex items-center gap-2">
          <UserPlus className="w-5 h-5" />
          Nouvel utilisateur
        </button>
      </div>

      {/* Filters */}
      <div className="card p-4">
        <div className="flex flex-col lg:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Rechercher par nom ou email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input pl-10"
            />
          </div>
          <select
            value={filterRole}
            onChange={(e) => setFilterRole(e.target.value)}
            className="input lg:w-48"
          >
            <option value="all">Tous les rôles</option>
            <option value="driver">Chauffeurs</option>
            <option value="passenger">Passagers</option>
          </select>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="input lg:w-48"
          >
            <option value="all">Tous les statuts</option>
            <option value="active">Actifs</option>
            <option value="suspended">Suspendus</option>
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-100/30">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Utilisateur</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Contact</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Rôle</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Statut</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Trajets</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Inscription</th>
                <th className="px-6 py-3 text-right text-xs font-semibold text-gray-600 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100/30">
              {filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50/50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-green-light rounded-full flex items-center justify-center">
                        <span className="text-green font-semibold text-sm">
                          {user.name.split(' ').map(n => n[0]).join('')}
                        </span>
                      </div>
                      <div>
                        <div className="font-semibold text-gray-900 dark:text-white">{user.name}</div>
                        <div className="text-sm text-gray-600 flex items-center gap-1">
                          <Mail className="w-3 h-3" />
                          {user.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-600 flex items-center gap-1">
                      <Phone className="w-3 h-3" />
                      {user.phone}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`badge ${user.role === 'driver' ? 'badge-warning' : 'badge-gray'}`}>
                      {user.role === 'driver' ? 'Chauffeur' : 'Passager'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`badge ${user.status === 'active' ? 'badge-success' : 'badge-error'}`}>
                      {user.status === 'active' ? 'Actif' : 'Suspendu'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm font-semibold text-gray-900 dark:text-white">{user.trips}</td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-600 flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      {new Date(user.joined).toLocaleDateString('fr-FR')}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button className="p-2 hover:bg-gray-50 rounded-btn">
                      <MoreVertical className="w-5 h-5 text-gray-600 dark:text-gray-400" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
