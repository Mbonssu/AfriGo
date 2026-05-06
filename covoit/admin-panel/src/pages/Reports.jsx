import { useState } from 'react'
import { AlertTriangle, User, Car, MessageSquare, Clock, CheckCircle, XCircle } from 'lucide-react'

const mockReports = [
  {
    id: 1,
    type: 'driver',
    reporter: 'Marie Ngo',
    reported: 'Jean Kamga',
    reason: 'Conduite dangereuse',
    description: 'Le chauffeur roulait trop vite et ne respectait pas le code de la route. J\'ai eu très peur pendant tout le trajet.',
    tripId: 'YA-DLA-001',
    status: 'pending',
    severity: 'high',
    createdAt: '2026-05-09 14:30',
  },
  {
    id: 2,
    type: 'passenger',
    reporter: 'Paul Mbida',
    reported: 'Sophie Talla',
    reason: 'Comportement inapproprié',
    description: 'La passagère était très impolie et a insulté les autres passagers.',
    tripId: 'DLA-YA-045',
    status: 'pending',
    severity: 'medium',
    createdAt: '2026-05-09 10:15',
  },
  {
    id: 3,
    type: 'driver',
    reporter: 'Alice Biya',
    reported: 'Eric Fouda',
    reason: 'Retard excessif',
    description: 'Le chauffeur est arrivé avec 2 heures de retard sans prévenir.',
    tripId: 'YA-KBI-023',
    status: 'resolved',
    severity: 'low',
    createdAt: '2026-05-08 16:45',
    resolvedAt: '2026-05-09 09:20',
    resolution: 'Avertissement envoyé au chauffeur. Remboursement partiel accordé.',
  },
  {
    id: 4,
    type: 'technical',
    reporter: 'David Onana',
    reported: null,
    reason: 'Bug de paiement',
    description: 'Mon paiement a été débité deux fois pour la même réservation.',
    tripId: 'DLA-LBE-012',
    status: 'resolved',
    severity: 'high',
    createdAt: '2026-05-07 11:30',
    resolvedAt: '2026-05-08 14:10',
    resolution: 'Remboursement effectué. Bug corrigé dans le système de paiement.',
  },
  {
    id: 5,
    type: 'driver',
    reporter: 'Fatima Njoya',
    reported: 'Thomas Nkoa',
    reason: 'Véhicule en mauvais état',
    description: 'La voiture était sale et sentait mauvais. Les sièges étaient déchirés.',
    tripId: 'YA-DLA-089',
    status: 'investigating',
    severity: 'medium',
    createdAt: '2026-05-09 08:00',
  },
]

export default function Reports() {
  const [filter, setFilter] = useState('pending')
  const [selectedReport, setSelectedReport] = useState(null)

  const filteredReports = mockReports.filter(report => 
    filter === 'all' || report.status === filter
  )

  const handleResolve = (id) => {
    const resolution = prompt('Résolution du signalement:')
    if (resolution) {
      console.log('Résoudre:', id, resolution)
      // TODO: Appel API
      setSelectedReport(null)
    }
  }

  const handleDismiss = (id) => {
    if (confirm('Êtes-vous sûr de vouloir rejeter ce signalement ?')) {
      console.log('Rejeter:', id)
      // TODO: Appel API
      setSelectedReport(null)
    }
  }

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'high': return 'text-coral bg-coral-light'
      case 'medium': return 'text-prime bg-prime-bg'
      case 'low': return 'text-gray-600 bg-gray-100'
      default: return 'text-gray-600 bg-gray-100'
    }
  }

  const getTypeIcon = (type) => {
    switch (type) {
      case 'driver': return Car
      case 'passenger': return User
      case 'technical': return AlertTriangle
      default: return MessageSquare
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between items-start">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Signalements</h1>
          <p className="text-gray-600 mt-1">
            {mockReports.filter(r => r.status === 'pending').length} signalements en attente
          </p>
        </div>

        {/* Filters */}
        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'all'
                ? 'bg-green text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Tous ({mockReports.length})
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'pending'
                ? 'bg-coral text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            En attente ({mockReports.filter(r => r.status === 'pending').length})
          </button>
          <button
            onClick={() => setFilter('investigating')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'investigating'
                ? 'bg-prime text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            En cours ({mockReports.filter(r => r.status === 'investigating').length})
          </button>
          <button
            onClick={() => setFilter('resolved')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'resolved'
                ? 'bg-green text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Résolus ({mockReports.filter(r => r.status === 'resolved').length})
          </button>
        </div>
      </div>

      {/* Reports List */}
      <div className="space-y-4">
        {filteredReports.map((report) => {
          const TypeIcon = getTypeIcon(report.type)
          return (
            <div key={report.id} className="card p-6">
              <div className="flex items-start gap-4">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                  report.severity === 'high' ? 'bg-coral-light' :
                  report.severity === 'medium' ? 'bg-prime-bg' :
                  'bg-gray-100'
                }`}>
                  <TypeIcon className={`w-6 h-6 ${
                    report.severity === 'high' ? 'text-coral' :
                    report.severity === 'medium' ? 'text-prime' :
                    'text-gray-600'
                  }`} />
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-4 mb-2">
                    <div>
                      <h3 className="font-bold text-gray-900 dark:text-white">{report.reason}</h3>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        Signalé par <span className="font-semibold">{report.reporter}</span>
                        {report.reported && (
                          <> contre <span className="font-semibold">{report.reported}</span></>
                        )}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`badge ${getSeverityColor(report.severity)}`}>
                        {report.severity === 'high' ? 'Urgent' :
                         report.severity === 'medium' ? 'Moyen' :
                         'Faible'}
                      </span>
                      <span className={`badge ${
                        report.status === 'resolved' ? 'badge-success' :
                        report.status === 'investigating' ? 'badge-warning' :
                        'badge-error'
                      }`}>
                        {report.status === 'resolved' ? 'Résolu' :
                         report.status === 'investigating' ? 'En cours' :
                         'En attente'}
                      </span>
                    </div>
                  </div>

                  <p className="text-sm text-gray-700 mb-3">{report.description}</p>

                  <div className="flex items-center gap-4 text-xs text-gray-500 mb-3">
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {report.createdAt}
                    </span>
                    <span>Trajet: {report.tripId}</span>
                  </div>

                  {report.resolution && (
                    <div className="bg-green-light border border-green/20 rounded-btn p-3 mb-3">
                      <p className="text-sm font-semibold text-green mb-1">Résolution:</p>
                      <p className="text-sm text-gray-700">{report.resolution}</p>
                      {report.resolvedAt && (
                        <p className="text-xs text-gray-500 mt-1">Résolu le {report.resolvedAt}</p>
                      )}
                    </div>
                  )}

                  {report.status !== 'resolved' && (
                    <div className="flex gap-2">
                      <button
                        onClick={() => setSelectedReport(report)}
                        className="btn-secondary text-sm py-2 px-4"
                      >
                        Examiner
                      </button>
                      <button
                        onClick={() => handleResolve(report.id)}
                        className="bg-green text-white px-4 py-2 rounded-btn text-sm font-semibold hover:bg-green-dark transition-colors flex items-center gap-2"
                      >
                        <CheckCircle className="w-4 h-4" />
                        Résoudre
                      </button>
                      <button
                        onClick={() => handleDismiss(report.id)}
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
      {selectedReport && (
        <div className="fixed inset-0 bg-gray-900/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-card max-w-2xl w-full max-h-[90vh] overflow-auto">
            <div className="sticky top-0 bg-white border-b border-gray-100/30 px-6 py-4 flex items-center justify-between">
              <h3 className="font-bold text-gray-900 dark:text-white">Détails du signalement</h3>
              <button
                onClick={() => setSelectedReport(null)}
                className="p-2 hover:bg-gray-50 rounded-btn"
              >
                <XCircle className="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Informations</h4>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">Type:</span>
                    <span className="font-medium">{selectedReport.type}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">Signalé par:</span>
                    <span className="font-medium">{selectedReport.reporter}</span>
                  </div>
                  {selectedReport.reported && (
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Signalé contre:</span>
                      <span className="font-medium">{selectedReport.reported}</span>
                    </div>
                  )}
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">Trajet:</span>
                    <span className="font-medium">{selectedReport.tripId}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">Date:</span>
                    <span className="font-medium">{selectedReport.createdAt}</span>
                  </div>
                </div>
              </div>

              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Description</h4>
                <p className="text-sm text-gray-700">{selectedReport.description}</p>
              </div>

              {selectedReport.status !== 'resolved' && (
                <div className="flex gap-3 pt-4">
                  <button
                    onClick={() => handleResolve(selectedReport.id)}
                    className="flex-1 btn-primary flex items-center justify-center gap-2"
                  >
                    <CheckCircle className="w-5 h-5" />
                    Résoudre
                  </button>
                  <button
                    onClick={() => handleDismiss(selectedReport.id)}
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
