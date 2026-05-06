import { Users, Car, AlertTriangle, MessageSquare, TrendingUp, TrendingDown, ShieldCheck, Scale } from 'lucide-react'
import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts'

// Données simulées
const stats = [
  { 
    name: 'Utilisateurs actifs', 
    value: '2,847', 
    change: '+12.5%', 
    trend: 'up', 
    icon: Users,
    color: 'green'
  },
  { 
    name: 'Signalements', 
    value: '23', 
    change: '-8.2%', 
    trend: 'down', 
    icon: AlertTriangle,
    color: 'coral'
  },
  { 
    name: 'KYC en attente', 
    value: '12', 
    change: '+3.1%', 
    trend: 'up', 
    icon: ShieldCheck,
    color: 'prime'
  },
  { 
    name: 'Litiges actifs', 
    value: '8', 
    change: '-15.3%', 
    trend: 'down', 
    icon: Scale,
    color: 'green'
  },
]

const userGrowthData = [
  { name: 'Jan', users: 1200 },
  { name: 'Fév', users: 1450 },
  { name: 'Mar', users: 1680 },
  { name: 'Avr', users: 2100 },
  { name: 'Mai', users: 2847 },
]

const reportsByType = [
  { name: 'Conduite', value: 35, color: '#D85A30' },
  { name: 'Comportement', value: 28, color: '#EF9F27' },
  { name: 'Technique', value: 20, color: '#1D9E75' },
  { name: 'Autre', value: 17, color: '#888780' },
]

const kycStats = [
  { name: 'Lun', approved: 5, rejected: 2 },
  { name: 'Mar', approved: 8, rejected: 1 },
  { name: 'Mer', approved: 6, rejected: 3 },
  { name: 'Jeu', approved: 10, rejected: 2 },
  { name: 'Ven', approved: 12, rejected: 1 },
]

const recentActivity = [
  { id: 1, type: 'kyc', user: 'Jean Kamga', action: 'Soumission KYC', time: 'Il y a 5 min', status: 'pending' },
  { id: 2, type: 'report', user: 'Marie Ngo', action: 'Signalement: Conduite dangereuse', time: 'Il y a 12 min', status: 'urgent' },
  { id: 3, type: 'suggestion', user: 'Paul Mbida', action: 'Nouvelle suggestion', time: 'Il y a 23 min', status: 'info' },
  { id: 4, type: 'dispute', user: 'Sophie Talla', action: 'Litige: Remboursement', time: 'Il y a 45 min', status: 'warning' },
  { id: 5, type: 'kyc', user: 'Eric Fouda', action: 'KYC approuvé', time: 'Il y a 1h', status: 'success' },
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
                stat.color === 'green' ? 'bg-green-light' :
                stat.color === 'coral' ? 'bg-coral-light' :
                'bg-prime-bg'
              }`}>
                <stat.icon className={`w-6 h-6 ${
                  stat.color === 'green' ? 'text-green' :
                  stat.color === 'coral' ? 'text-coral' :
                  'text-prime'
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
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-1">{stat.value}</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">{stat.name}</p>
          </div>
        ))}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Croissance utilisateurs */}
        <div className="card p-6">
          <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Croissance des utilisateurs</h3>
          <ResponsiveContainer width="100%" height={250}>
            <LineChart data={userGrowthData}>
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
                dataKey="users" 
                stroke="#1D9E75" 
                strokeWidth={2}
                dot={{ fill: '#1D9E75', r: 4 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Signalements par type */}
        <div className="card p-6">
          <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Signalements par type</h3>
          <ResponsiveContainer width="100%" height={250}>
            <PieChart>
              <Pie
                data={reportsByType}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {reportsByType.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Vérifications KYC */}
        <div className="card p-6 lg:col-span-2">
          <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Vérifications KYC cette semaine</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={kycStats}>
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
              <Legend />
              <Bar dataKey="approved" fill="#1D9E75" name="Approuvés" radius={[8, 8, 0, 0]} />
              <Bar dataKey="rejected" fill="#D85A30" name="Rejetés" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="card">
        <div className="px-6 py-4 border-b border-gray-100/30 dark:border-gray-700/30">
          <h3 className="text-lg font-bold text-gray-900 dark:text-white">Activité récente</h3>
        </div>
        <div className="divide-y divide-gray-100/30 dark:divide-gray-700/30">
          {recentActivity.map((activity) => (
            <div key={activity.id} className="px-6 py-4 hover:bg-gray-50/50 dark:hover:bg-gray-700/50 flex items-center gap-4">
              <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                activity.status === 'urgent' ? 'bg-coral-light dark:bg-coral/20' :
                activity.status === 'warning' ? 'bg-prime-bg dark:bg-prime/20' :
                activity.status === 'success' ? 'bg-green-light dark:bg-green/20' :
                'bg-gray-100 dark:bg-gray-700'
              }`}>
                {activity.type === 'kyc' && <ShieldCheck className={`w-5 h-5 ${
                  activity.status === 'success' ? 'text-green' : 'text-prime'
                }`} />}
                {activity.type === 'report' && <AlertTriangle className="w-5 h-5 text-coral" />}
                {activity.type === 'suggestion' && <MessageSquare className="w-5 h-5 text-gray-600 dark:text-gray-400" />}
                {activity.type === 'dispute' && <Scale className="w-5 h-5 text-prime" />}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-900 dark:text-white">{activity.action}</p>
                <p className="text-xs text-gray-600 dark:text-gray-400">{activity.user}</p>
              </div>
              <span className="text-xs text-gray-500 dark:text-gray-400">{activity.time}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
