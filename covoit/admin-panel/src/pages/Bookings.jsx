export default function Bookings() {
  const mockBookings = [
    { id: 1, passenger: 'Marie Ngo', trip: 'Yaoundé → Douala', driver: 'Jean Kamga', seats: 2, amount: 9000, status: 'confirmed', date: '2026-05-10' },
    { id: 2, passenger: 'Sophie Talla', trip: 'Douala → Bafoussam', driver: 'Paul Mbida', seats: 1, amount: 6000, status: 'pending', date: '2026-05-10' },
    { id: 3, passenger: 'Alice Biya', trip: 'Yaoundé → Kribi', driver: 'Eric Fouda', seats: 1, amount: 5500, status: 'confirmed', date: '2026-05-11' },
    { id: 4, passenger: 'David Onana', trip: 'Douala → Limbé', driver: 'Thomas Nkoa', seats: 2, amount: 6000, status: 'completed', date: '2026-05-09' },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Réservations</h1>
        <p className="text-gray-600 mt-1">{mockBookings.length} réservations</p>
      </div>

      <div className="card overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-100/30">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Passager</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Trajet</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Chauffeur</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Places</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Statut</th>
              <th className="px-6 py-3 text-right text-xs font-semibold text-gray-600 uppercase">Montant</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100/30">
            {mockBookings.map((booking) => (
              <tr key={booking.id} className="hover:bg-gray-50/50">
                <td className="px-6 py-4 font-medium text-gray-900 dark:text-white">{booking.passenger}</td>
                <td className="px-6 py-4 text-sm text-gray-600 dark:text-gray-400">{booking.trip}</td>
                <td className="px-6 py-4 text-sm text-gray-600 dark:text-gray-400">{booking.driver}</td>
                <td className="px-6 py-4 text-sm font-semibold text-gray-900 dark:text-white">{booking.seats}</td>
                <td className="px-6 py-4">
                  <span className={`badge ${
                    booking.status === 'completed' ? 'badge-success' :
                    booking.status === 'confirmed' ? 'badge-success' :
                    booking.status === 'pending' ? 'badge-warning' :
                    'badge-gray'
                  }`}>
                    {booking.status === 'completed' ? 'Terminé' :
                     booking.status === 'confirmed' ? 'Confirmé' :
                     booking.status === 'pending' ? 'En attente' :
                     booking.status}
                  </span>
                </td>
                <td className="px-6 py-4 text-right font-semibold text-gray-900 dark:text-white">{booking.amount} FCFA</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
