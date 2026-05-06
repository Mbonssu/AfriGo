import { useState } from 'react'
import { Scale, User, DollarSign, Clock, CheckCircle, XCircle } from 'lucide-react'

const mockDisputes = [
  {
    id: 1,
    type: 'refund',
    claimant: 'Marie Ngo',
    defendant: 'Jean Kamga (Chauffeur)',
    amount: 4500,
    reason: 'Trajet annulé par le chauffeur',
    description: 'Le chauffeur a annulé le trajet 10 minutes avant le départ sans raison valable. Je demande un remboursement complet.',
    tripId: 'YA-DLA-001',
    status: 'pending',
    createdAt: '2026-05-09 14:30',
    evidence: ['screenshot1.jpg', 'conversation.jpg'],
  },
  {
    id: 2,
    type: 'payment',
    claimant: 'Paul Mbida (Chauffeur)',
    defendant: 'Sophie Talla',
    amount: 6000,
    reason: 'Paiement non reçu',
    description: 'La passagère dit avoir payé mais je n\'ai rien reçu sur mon compte.',
    tripId: 'DLA-YA-045',
    status: 'investigating',
    createdAt: '2026-05-08 10:15',
    evidence: ['transaction.jpg'],
  },
  {
    id: 3,
    type: 'service',
    claimant: 'Alice Biya',
    defendant: 'Eric Fouda (Chauffeur)',
    amount: 2000,
    reason: 'Service non conforme',
    description: 'Le chauffeur n\'a pas respecté l\'itinéraire convenu et m\'a déposée à 5km de ma destination.',
    tripId: 'YA-KBI-023',
    status: 'resolved',
    createdAt: '2026-05-07 16:45',
    resolvedAt: '2026-05-08 09:20',
    resolution: 'Remboursement partiel de 2000 FCFA accordé à la passagère.',
    evidence: ['gps_route.jpg'],
  },
  {
    id: 4,
    type: 'damage',
    claimant: 'Thomas Nkoa (Chauffeur)',
    defendant: 'David Onana',
    amount: 15000,
    reason: 'Dommages au véhicule',
    description: 'Le passager a endommagé le siège arrière avec un objet pointu.',
    tripId: 'DLA-LBE-012',
    status: 'pending',
    createdAt: '2026-05-09 11:30',
    evidence: ['damage1.jpg', 'damage2.jpg', 'damage3.jpg'],
  },
]

export default function Disputes() {
  const [filter, setFilter] = useState('pending')
  const [selectedDispute, setSelectedDispute] = useState(null)

  const filteredDisputes = mockDisputes.filter(dispute => 
    filter === 'all' || dispute.status === filter
  )

  const handleResolve = (id) => {
    const resolution = prompt('Résolution du litige:')
    if (resolution) {
      console.log('Résoudre:', id, resolution)
      // TODO: Appel API
      setSelectedDispute(null)
    }
  }

  const handleReject = (id) => {
    if (confirm('Êtes-vous sûr de vouloir rejeter ce litige ?')) {
      console.log('Rejeter:', id)
      // TODO: Appel API
      setSelectedDispute(null)
    }
  }

  const getTypeIcon = (type) => {
    switch (type) {
      case 'refund': return DollarSign
      case 'payment': return DollarSign
      case 'service': return User
      case 'damage': return Scale
      default: return Scale
    }
  }

  const getTypeLabel = (type) => {
    switch (type) {
      case 'refund': return 'Remboursement'
      case 'payment': return 'Paiement'
      case 'service': return 'Service'
      case 'damage': return 'Dommages'
      default: return type
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between items-start">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Litiges</h1>
          <p className="text-gray-600 mt-1">
            {mockDisputes.filter(d => d.status === 'pending').length} litiges en attente
          </p>
        </div>

        {/* Filters */}
        <div className="flex gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'all'
                ? 'bg-green text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Tous ({mockDisputes.length})
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'pending'
                ? 'bg-coral text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            En attente ({mockDisputes.filter(d => d.status === 'pending').length})
          </button>
          <button
            onClick={() => setFilter('investigating')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'investigating'
                ? 'bg-prime text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            En cours ({mockDisputes.filter(d => d.status === 'investigating').length})
          </button>
          <button
            onClick={() => setFilter('resolved')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'resolved'
                ? 'bg-green text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Résolus ({mockDisputes.filter(d => d.status === 'resolved').length})
          </button>
        </div>
      </div>

      {/* Disputes List */}
      <div className="space-y-4">
        {filteredDisputes.map((dispute) => {
          const TypeIcon = getTypeIcon(dispute.type)
          return (
            <div key={dispute.id} className="card p-6">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-coral-light rounded-xl flex items-center justify-center">
                  <TypeIcon className="w-6 h-6 text-coral" />
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-4 mb-2">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <span className="badge bg-coral-light text-coral">
                          {getTypeLabel(dispute.type)}
                        </span>
                        <span className={`badge ${
                          dispute.status === 'resolved' ? 'badge-success' :
                          dispute.status === 'investigating' ? 'badge-warning' :
                          'badge-error'
                        }`}>
                          {dispute.status === 'resolved' ? 'Résolu' :
                           dispute.status === 'investigating' ? 'En cours' :
                           'En attente'}
                        </span>
                      </div>
                      <h3 className="font-bold text-gray-900 dark:text-white">{dispute.reason}</h3>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        <span className="font-semibold">{dispute.claimant}</span> vs{' '}
                        <span className="font-semibold">{dispute.defendant}</span>
                      </p>
                    </div>
                    <div className="text-right">
                      <div className="text-2xl font-bold text-coral">{dispute.amount.toLocaleString()} FCFA</div>
                      <div className="text-xs text-gray-500">Montant en litige</div>
                    </div>
                  </div>

                  <p className="text-sm text-gray-700 mb-3">{dispute.description}</p>

                  {dispute.evidence && dispute.evidence.length > 0 && (
                    <div className="bg-gray-50 rounded-btn p-3 mb-3">
                      <p className="text-sm font-semibold text-gray-900 mb-2">
                        Preuves ({dispute.evidence.length})
                      </p>
                      <div className="flex gap-2 flex-wrap">
                        {dispute.evidence.map((file, idx) => (
                          <span key={idx} className="text-xs bg-white px-2 py-1 rounded border border-gray-200">
                            {file}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}

                  {dispute.resolution && (
                    <div className="bg-green-light border border-green/20 rounded-btn p-3 mb-3">
                      <p className="text-sm font-semibold text-green mb-1">Résolution:</p>
                      <p className="text-sm text-gray-700">{dispute.resolution}</p>
                      {dispute.resolvedAt && (
                        <p className="text-xs text-gray-500 mt-1">Résolu le {dispute.resolvedAt}</p>
                      )}
                    </div>
                  )}

                  <div className="flex items-center gap-4 text-xs text-gray-500 mb-3">
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {dispute.createdAt}
                    </span>
                    <span>Trajet: {dispute.tripId}</span>
                  </div>

                  {dispute.status !== 'resolved' && (
                    <div className="flex gap-2">
                      <button
                        onClick={() => setSelectedDispute(dispute)}
                        className="btn-secondary text-sm py-2 px-4"
                      >
                        Examiner
                      </button>
                      <button
                        onClick={() => handleResolve(dispute.id)}
                        className="bg-green text-white px-4 py-2 rounded-btn text-sm font-semibold hover:bg-green-dark transition-colors flex items-center gap-2"
                      >
                        <CheckCircle className="w-4 h-4" />
                        Résoudre
                      </button>
                      <button
                        onClick={() => handleReject(dispute.id)}
                        className="bg-gray-100 text-gray-600 px-4 py-2 rounded-btn text-sm font-semibold hover:bg-gray-200 transition-colors flex items-center gap-2"
                      >
                        <XCircle className="w-4 h-4" />
                        Rejeter
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {/* Detail Modal */}
      {selectedDispute && (
        <div className="fixed inset-0 bg-gray-900/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-card max-w-3xl w-full max-h-[90vh] overflow-auto">
            <div className="sticky top-0 bg-white border-b border-gray-100/30 px-6 py-4 flex items-center justify-between">
              <h3 className="font-bold text-gray-900 dark:text-white">Détails du litige</h3>
              <button
                onClick={() => setSelectedDispute(null)}
                className="p-2 hover:bg-gray-50 rounded-btn"
              >
                <XCircle className="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h4 className="font-semibold text-gray-900 mb-2">Demandeur</h4>
                  <p className="text-sm text-gray-700">{selectedDispute.claimant}</p>
                </div>
                <div>
                  <h4 className="font-semibold text-gray-900 mb-2">Défendeur</h4>
                  <p className="text-sm text-gray-700">{selectedDispute.defendant}</p>
                </div>
              </div>

              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Montant</h4>
                <p className="text-2xl font-bold text-coral">{selectedDispute.amount.toLocaleString()} FCFA</p>
              </div>

              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Description</h4>
                <p className="text-sm text-gray-700">{selectedDispute.description}</p>
              </div>

              {selectedDispute.evidence && selectedDispute.evidence.length > 0 && (
                <div>
                  <h4 className="font-semibold text-gray-900 mb-2">Preuves</h4>
                  <div className="grid grid-cols-3 gap-2">
                    {selectedDispute.evidence.map((file, idx) => (
                      <div key={idx} className="bg-gray-100 rounded-btn h-32 flex items-center justify-center">
                        <p className="text-xs text-gray-500">{file}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {selectedDispute.status !== 'resolved' && (
                <div className="flex gap-3 pt-4">
                  <button
                    onClick={() => handleResolve(selectedDispute.id)}
                    className="flex-1 btn-primary flex items-center justify-center gap-2"
                  >
                    <CheckCircle className="w-5 h-5" />
                    Résoudre
                  </button>
                  <button
                    onClick={() => handleReject(selectedDispute.id)}
                    className="flex-1 bg-gray-100 text-gray-600 px-5 py-3 rounded-btn font-semibold hover:bg-gray-200 transition-colors flex items-center justify-center gap-2"
                  >
                    <XCircle className="w-5 h-5" />
                    Rejeter
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
