import { CreditCard, CheckCircle, Clock, XCircle } from 'lucide-react'

export default function Payments() {
  const mockPayments = [
    { id: 1, user: 'Marie Ngo', amount: 9000, method: 'MTN Mobile Money', status: 'completed', date: '2026-05-09 14:23', ref: 'MTN-2024-001234' },
    { id: 2, user: 'Sophie Talla', amount: 6000, method: 'Orange Money', status: 'pending', date: '2026-05-09 15:45', ref: 'OM-2024-005678' },
    { id: 3, user: 'Alice Biya', amount: 5500, method: 'MTN Mobile Money', status: 'completed', date: '2026-05-09 10:12', ref: 'MTN-2024-001235' },
    { id: 4, user: 'David Onana', amount: 6000, method: 'Orange Money', status: 'failed', date: '2026-05-08 18:30', ref: 'OM-2024-005679' },
  ]

  const totalAmount = mockPayments.filter(p => p.status === 'completed').reduce((sum, p) => sum + p.amount, 0)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Paiements</h1>
        <p className="text-gray-600 mt-1">{mockPayments.length} transactions</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 bg-green-light rounded-xl flex items-center justify-center">
              <CheckCircle className="w-5 h-5 text-green" />
            </div>
            <span className="text-sm font-semibold text-gray-600 dark:text-gray-400">Complétés</span>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white">{totalAmount.toLocaleString()} FCFA</div>
        </div>

        <div className="card p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 bg-prime-bg rounded-xl flex items-center justify-center">
              <Clock className="w-5 h-5 text-prime" />
            </div>
            <span className="text-sm font-semibold text-gray-600 dark:text-gray-400">En attente</span>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {mockPayments.filter(p => p.status === 'pending').length}
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 bg-coral-light rounded-xl flex items-center justify-center">
              <XCircle className="w-5 h-5 text-coral" />
            </div>
            <span className="text-sm font-semibold text-gray-600 dark:text-gray-400">Échoués</span>
          </div>
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {mockPayments.filter(p => p.status === 'failed').length}
          </div>
        </div>
      </div>

      <div className="card overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-100/30">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Utilisateur</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Méthode</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Référence</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Date</th>
              <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Statut</th>
              <th className="px-6 py-3 text-right text-xs font-semibold text-gray-600 uppercase">Montant</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100/30">
            {mockPayments.map((payment) => (
              <tr key={payment.id} className="hover:bg-gray-50/50">
                <td className="px-6 py-4 font-medium text-gray-900 dark:text-white">{payment.user}</td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                    <CreditCard className="w-4 h-4" />
                    {payment.method}
                  </div>
                </td>
                <td className="px-6 py-4 text-sm font-mono text-gray-600 dark:text-gray-400">{payment.ref}</td>
                <td className="px-6 py-4 text-sm text-gray-600 dark:text-gray-400">{payment.date}</td>
                <td className="px-6 py-4">
                  <span className={`badge ${
                    payment.status === 'completed' ? 'badge-success' :
                    payment.status === 'pending' ? 'badge-warning' :
                    'badge-error'
                  }`}>
                    {payment.status === 'completed' ? 'Complété' :
                     payment.status === 'pending' ? 'En attente' :
                     'Échoué'}
                  </span>
                </td>
                <td className="px-6 py-4 text-right font-semibold text-gray-900 dark:text-white">
                  {payment.amount.toLocaleString()} FCFA
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
