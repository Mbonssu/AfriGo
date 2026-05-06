import { Users, Car, Route, CreditCard, TrendingUp, TrendingDown } from 'lucide-react'
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

// Données simulées
const stats = [
  { 
    name: 'Utilisateurs', 
    value: '2,847', 
    change: '+12.5%', 
    trend: 'up', 
    icon: Users,
    color: 'green'
  },
  { 
    name: 'Chauffeurs actifs', 
    value: '342', 
    change: '+8.2%', 
    trend: 'up', 
    icon: Car,
    color: 'prime'
  },
  { 
    name: 'Trajets ce mois', 
    value: '1,234', 
    change: '-3.1%', 
    trend: 'down', 
    icon: Route,
    color: 'green'
  },
  { 
    name: 'Revenus (FCFA)', 
    value: '12.4M', 
    change: '+15.3%', 
    trend: 'up', 
    icon: CreditCard,
    color: 'prime'
  },
]

const chartData = [
  { name: 'Lun', trajets: 45, revenus: 180 },
  { name: 'Mar', trajets: 52, revenus: 210 },
  { name: 'Mer', trajets: 48, revenus: 195 },
  { name: 'Jeu', trajets: 61, revenus: 245 },
  { name: 'Ven', trajets: 73, revenus: 290 },
  { name: 'Sam', trajets: 89, revenus: 355 },
  { name: 'Dim', trajets: 67, revenus: 270 },
]

const recentTrips = [
  { id: 1, from: 'Yaoundé', to: 'Douala', driver: 'Jean Kamga', status: 'completed', amount: '4500' },
  { id: 2, from: 'Douala', to: 'Bafoussam', driver: 'Marie Ngo', status: 'ongoing', amount: '6000' },
  { id: 3, from: 'Yaoundé', to: 'Kribi', driver: 'Paul Mbida', status: 'active', amount: '5500' },
  { id: 4, from: 'Douala', to: 'Limbé', driver: 'Sophie Talla', status: 'completed', amount: '3000' },
  { id: 5, from: 'Yaoundé', to: 'Ngaoundéré', driver: 'Eric Fouda', status: 'active', amount: '12000' },
]

export default function Dashboard() {
  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <div key={stat.name} className="card p-6">
            <div className="flex items-center justify-between mb-4">
              <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                stat.color === 'green' ? 'bg-green-light' : 'bg-prime-bg'
              }`}>
                <stat.icon className={`w-6 h-6 ${
                  stat.color === 'green' ? 'text-green' : 'text-prime'
                }`} />
              </div>
              <div className={`flex items-center gap-1 text-sm font-semibold ${
                stat.trend === 'up' ? 'text-green' : 'text-coral'
              }`}>
                {stat.trend === 'up' ? (
                  <TrendingUp className="w-4 h-4" />
                ) : (
                  <TrendingDown className="w-4 h-4" />
                )}
                {stat.change}
              </div>
            </div>
            <h3 className="text-2xl font-bold text-gray-900 mb-1">{stat.value}</h3>
            <p className="text-sm text-gray-600">{stat.name}</p>
          </div>
        ))}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Trajets par jour */}
        <div className="card p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-4">Trajets cette semaine</h3>
          <ResponsiveContainer width="100%" height={250}>
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#D3D1C7" />
              <XAxis dataKey="name" stroke="#888780" style={{ fontSize: '12px' }} />
              <YAxis stroke="#888780" style={{ fontSize: '12px' }} />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: '#fff', 
                  border: '1px solid #D3D1C7',
                  borderRadius: '12px',
                  fontSize: '12px'
                }} 
              />
              <Line 
                type="monotone" 
                dataKey="trajets" 
                stroke="#1D9E75" 
                strokeWidth={2}
                dot={{ fill: '#1D9E75', r: 4 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Revenus par jour */}
        <div className="card p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-4">Revenus cette semaine (x1000 FCFA)</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#D3D1C7" />
              <XAxis dataKey="name" stroke="#888780" style={{ fontSize: '12px' }} />
              <YAxis stroke="#888780" style={{ fontSize: '12px' }} />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: '#fff', 
                  border: '1px solid #D3D1C7',
                  borderRadius: '12px',
                  fontSize: '12px'
                }} 
              />
              <Bar dataKey="revenus" fill="#EF9F27" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent Trips */}
      <div className="card">
        <div className="px-6 py-4 border-b border-gray-100/30">
          <h3 className="text-lg font-bold text-gray-900">Trajets récents</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-100/30">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Trajet</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Chauffeur</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Statut</th>
                <th className="px-6 py-3 text-right text-xs font-semibold text-gray-600 uppercase">Montant</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100/30">
              {recentTrips.map((trip) => (
                <tr key={trip.id} className="hover:bg-gray-50/50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2 text-sm font-medium text-gray-900">
                      {trip.from}
                      <span className="text-gray-400">→</span>
                      {trip.to}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">{trip.driver}</td>
                  <td className="px-6 py-4">
                    <span className={`badge ${
                      trip.status === 'completed' ? 'badge-success' :
                      trip.status === 'ongoing' ? 'badge-warning' :
                      'badge-gray'
                    }`}>
                      {trip.status === 'completed' ? 'Terminé' :
                       trip.status === 'ongoing' ? 'En cours' :
                       'Actif'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right text-sm font-semibold text-gray-900">
                    {trip.amount} FCFA
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
