import { Car, Star, CheckCircle, XCircle } from 'lucide-react'

const mockDrivers = [
  { id: 1, name: 'Jean Kamga', rating: 4.8, trips: 45, vehicle: 'Toyota Corolla', plate: 'YA-1234-AB', isPrime: true, verified: true },
  { id: 2, name: 'Paul Mbida', rating: 4.9, trips: 67, vehicle: 'Honda Civic', plate: 'DLA-5678-CD', isPrime: true, verified: true },
  { id: 3, name: 'Eric Fouda', rating: 4.6, trips: 123, vehicle: 'Nissan Sentra', plate: 'YA-9012-EF', isPrime: false, verified: true },
  { id: 4, name: 'Thomas Nkoa', rating: 4.7, trips: 34, vehicle: 'Hyundai Accent', plate: 'DLA-3456-GH', isPrime: false, verified: false },
]

export default function Drivers() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Chauffeurs</h1>
        <p className="text-gray-600 mt-1">{mockDrivers.length} chauffeurs enregistrés</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {mockDrivers.map((driver) => (
          <div key={driver.id} className="card p-6">
            <div className="flex items-start justify-between mb-4">
              <div className="w-12 h-12 bg-green-light rounded-full flex items-center justify-center">
                <span className="text-green font-bold">
                  {driver.name.split(' ').map(n => n[0]).join('')}
                </span>
              </div>
              {driver.isPrime && (
                <span className="badge badge-warning">✨ Prime</span>
              )}
            </div>
            
            <h3 className="font-bold text-gray-900 mb-1">{driver.name}</h3>
            
            <div className="flex items-center gap-1 text-sm text-gray-600 mb-3">
              <Star className="w-4 h-4 fill-prime text-prime" />
              <span className="font-semibold">{driver.rating}</span>
              <span>· {driver.trips} trajets</span>
            </div>

            <div className="space-y-2 text-sm">
              <div className="flex items-center gap-2 text-gray-600">
                <Car className="w-4 h-4" />
                {driver.vehicle}
              </div>
              <div className="text-gray-600 font-mono text-xs">{driver.plate}</div>
              <div className="flex items-center gap-2">
                {driver.verified ? (
                  <span className="flex items-center gap-1 text-green text-xs">
                    <CheckCircle className="w-4 h-4" />
                    Vérifié
                  </span>
                ) : (
                  <span className="flex items-center gap-1 text-coral text-xs">
                    <XCircle className="w-4 h-4" />
                    Non vérifié
                  </span>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
