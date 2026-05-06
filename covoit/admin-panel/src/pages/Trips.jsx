import { MapPin, Calendar, Users as UsersIcon } from 'lucide-react'

const mockTrips = [
  { id: 1, from: 'Yaoundé', to: 'Douala', driver: 'Jean Kamga', date: '2026-05-10', time: '08:00', seats: 4, booked: 3, price: 4500, status: 'active' },
  { id: 2, from: 'Douala', to: 'Bafoussam', driver: 'Paul Mbida', date: '2026-05-10', time: '14:00', seats: 4, booked: 4, price: 6000, status: 'ongoing' },
  { id: 3, from: 'Yaoundé', to: 'Kribi', driver: 'Eric Fouda', date: '2026-05-11', time: '10:00', seats: 3, booked: 1, price: 5500, status: 'active' },
  { id: 4, from: 'Douala', to: 'Limbé', driver: 'Thomas Nkoa', date: '2026-05-09', time: '16:00', seats: 4, booked: 4, price: 3000, status: 'completed' },
]

export default function Trips() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Trajets</h1>
        <p className="text-gray-600 mt-1">{mockTrips.length} trajets enregistrés</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {mockTrips.map((trip) => (
          <div key={trip.id} className="card p-6">
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-2">
                <MapPin className="w-5 h-5 text-green" />
                <div>
                  <div className="font-bold text-gray-900 dark:text-white">{trip.from} → {trip.to}</div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">{trip.driver}</div>
                </div>
              </div>
              <span className={`badge ${
                trip.status === 'completed' ? 'badge-success' :
                trip.status === 'ongoing' ? 'badge-warning' :
                'badge-gray'
              }`}>
                {trip.status === 'completed' ? 'Terminé' :
                 trip.status === 'ongoing' ? 'En cours' :
                 'Actif'}
              </span>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                <Calendar className="w-4 h-4" />
                {new Date(trip.date).toLocaleDateString('fr-FR')} · {trip.time}
              </div>
              <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                <UsersIcon className="w-4 h-4" />
                {trip.booked}/{trip.seats} places
              </div>
            </div>

            <div className="flex items-center justify-between pt-4 border-t border-gray-100/30">
              <span className="text-2xl font-bold text-green">{trip.price} FCFA</span>
              <div className="w-full max-w-[120px] bg-gray-100 rounded-full h-2">
                <div 
                  className="bg-green h-2 rounded-full transition-all"
                  style={{ width: `${(trip.booked / trip.seats) * 100}%` }}
                />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
