import { useState } from 'react'
import { FileText, CheckCircle, XCircle, Clock, Eye, Download } from 'lucide-react'

const mockKYCSubmissions = [
  {
    id: 1,
    user: 'Jean Kamga',
    email: 'jean.kamga@email.com',
    phone: '+237 690 123 456',
    type: 'driver',
    status: 'pending',
    submittedAt: '2026-05-08 14:30',
    documents: {
      cni: { url: '/docs/cni-1.jpg', uploaded: true },
      license: { url: '/docs/license-1.jpg', uploaded: true },
      registration: { url: '/docs/reg-1.jpg', uploaded: true },
      photo: { url: '/docs/photo-1.jpg', uploaded: true },
    }
  },
  {
    id: 2,
    user: 'Marie Ngo',
    email: 'marie.ngo@email.com',
    phone: '+237 677 234 567',
    type: 'driver',
    status: 'pending',
    submittedAt: '2026-05-09 10:15',
    documents: {
      cni: { url: '/docs/cni-2.jpg', uploaded: true },
      license: { url: '/docs/license-2.jpg', uploaded: true },
      registration: { url: '/docs/reg-2.jpg', uploaded: true },
      photo: { url: '/docs/photo-2.jpg', uploaded: true },
    }
  },
  {
    id: 3,
    user: 'Paul Mbida',
    email: 'paul.mbida@email.com',
    phone: '+237 655 345 678',
    type: 'driver',
    status: 'approved',
    submittedAt: '2026-05-05 16:45',
    reviewedAt: '2026-05-06 09:20',
    documents: {
      cni: { url: '/docs/cni-3.jpg', uploaded: true },
      license: { url: '/docs/license-3.jpg', uploaded: true },
      registration: { url: '/docs/reg-3.jpg', uploaded: true },
      photo: { url: '/docs/photo-3.jpg', uploaded: true },
    }
  },
  {
    id: 4,
    user: 'Sophie Talla',
    email: 'sophie.talla@email.com',
    phone: '+237 698 456 789',
    type: 'driver',
    status: 'rejected',
    submittedAt: '2026-05-07 11:30',
    reviewedAt: '2026-05-08 14:10',
    rejectionReason: 'Photo de permis floue, impossible de lire les informations',
    documents: {
      cni: { url: '/docs/cni-4.jpg', uploaded: true },
      license: { url: '/docs/license-4.jpg', uploaded: true },
      registration: { url: '/docs/reg-4.jpg', uploaded: false },
      photo: { url: '/docs/photo-4.jpg', uploaded: true },
    }
  },
]

export default function KYCVerification() {
  const [filter, setFilter] = useState('pending')
  const [selectedSubmission, setSelectedSubmission] = useState(null)

  const filteredSubmissions = mockKYCSubmissions.filter(sub => 
    filter === 'all' || sub.status === filter
  )

  const handleApprove = (id) => {
    console.log('Approuver:', id)
    // TODO: Appel API pour approuver
    setSelectedSubmission(null)
  }

  const handleReject = (id) => {
    const reason = prompt('Raison du rejet:')
    if (reason) {
      console.log('Rejeter:', id, reason)
      // TODO: Appel API pour rejeter
      setSelectedSubmission(null)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between items-start">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Vérification KYC</h1>
          <p className="text-gray-600 mt-1">
            {mockKYCSubmissions.filter(s => s.status === 'pending').length} demandes en attente
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
            Tous ({mockKYCSubmissions.length})
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'pending'
                ? 'bg-prime text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            En attente ({mockKYCSubmissions.filter(s => s.status === 'pending').length})
          </button>
          <button
            onClick={() => setFilter('approved')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'approved'
                ? 'bg-green text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Approuvés ({mockKYCSubmissions.filter(s => s.status === 'approved').length})
          </button>
          <button
            onClick={() => setFilter('rejected')}
            className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
              filter === 'rejected'
                ? 'bg-coral text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Rejetés ({mockKYCSubmissions.filter(s => s.status === 'rejected').length})
          </button>
        </div>
      </div>

      {/* Submissions Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {filteredSubmissions.map((submission) => (
          <div key={submission.id} className="card p-6">
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-green-light rounded-full flex items-center justify-center">
                  <span className="text-green font-bold">
                    {submission.user.split(' ').map(n => n[0]).join('')}
                  </span>
                </div>
                <div>
                  <h3 className="font-bold text-gray-900 dark:text-white">{submission.user}</h3>
                  <p className="text-sm text-gray-600 dark:text-gray-400">{submission.email}</p>
                  <p className="text-xs text-gray-500">{submission.phone}</p>
                </div>
              </div>
              <span className={`badge ${
                submission.status === 'approved' ? 'badge-success' :
                submission.status === 'rejected' ? 'badge-error' :
                'badge-warning'
              }`}>
                {submission.status === 'approved' ? 'Approuvé' :
                 submission.status === 'rejected' ? 'Rejeté' :
                 'En attente'}
              </span>
            </div>

            {/* Documents */}
            <div className="space-y-2 mb-4">
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600 flex items-center gap-2">
                  <FileText className="w-4 h-4" />
                  CNI
                </span>
                {submission.documents.cni.uploaded ? (
                  <CheckCircle className="w-4 h-4 text-green" />
                ) : (
                  <XCircle className="w-4 h-4 text-coral" />
                )}
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600 flex items-center gap-2">
                  <FileText className="w-4 h-4" />
                  Permis de conduire
                </span>
                {submission.documents.license.uploaded ? (
                  <CheckCircle className="w-4 h-4 text-green" />
                ) : (
                  <XCircle className="w-4 h-4 text-coral" />
                )}
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600 flex items-center gap-2">
                  <FileText className="w-4 h-4" />
                  Carte grise
                </span>
                {submission.documents.registration.uploaded ? (
                  <CheckCircle className="w-4 h-4 text-green" />
                ) : (
                  <XCircle className="w-4 h-4 text-coral" />
                )}
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600 flex items-center gap-2">
                  <FileText className="w-4 h-4" />
                  Photo profil
                </span>
                {submission.documents.photo.uploaded ? (
                  <CheckCircle className="w-4 h-4 text-green" />
                ) : (
                  <XCircle className="w-4 h-4 text-coral" />
                )}
              </div>
            </div>

            {/* Rejection Reason */}
            {submission.status === 'rejected' && submission.rejectionReason && (
              <div className="bg-coral-light border border-coral/20 rounded-btn p-3 mb-4">
                <p className="text-sm text-coral font-medium">Raison du rejet:</p>
                <p className="text-sm text-gray-700 mt-1">{submission.rejectionReason}</p>
              </div>
            )}

            {/* Dates */}
            <div className="text-xs text-gray-500 mb-4">
              <div className="flex items-center gap-2">
                <Clock className="w-3 h-3" />
                Soumis le {submission.submittedAt}
              </div>
              {submission.reviewedAt && (
                <div className="flex items-center gap-2 mt-1">
                  <CheckCircle className="w-3 h-3" />
                  Traité le {submission.reviewedAt}
                </div>
              )}
            </div>

            {/* Actions */}
            <div className="flex gap-2">
              <button
                onClick={() => setSelectedSubmission(submission)}
                className="flex-1 btn-secondary flex items-center justify-center gap-2 text-sm py-2"
              >
                <Eye className="w-4 h-4" />
                Examiner
              </button>
              {submission.status === 'pending' && (
                <>
                  <button
                    onClick={() => handleApprove(submission.id)}
                    className="flex-1 bg-green text-white px-4 py-2 rounded-btn text-sm font-semibold hover:bg-green-dark transition-colors flex items-center justify-center gap-2"
                  >
                    <CheckCircle className="w-4 h-4" />
                    Approuver
                  </button>
                  <button
                    onClick={() => handleReject(submission.id)}
                    className="flex-1 bg-coral text-white px-4 py-2 rounded-btn text-sm font-semibold hover:bg-coral/90 transition-colors flex items-center justify-center gap-2"
                  >
                    <XCircle className="w-4 h-4" />
                    Rejeter
                  </button>
                </>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Document Viewer Modal */}
      {selectedSubmission && (
        <div className="fixed inset-0 bg-gray-900/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-card max-w-4xl w-full max-h-[90vh] overflow-auto">
            <div className="sticky top-0 bg-white border-b border-gray-100/30 px-6 py-4 flex items-center justify-between">
              <h3 className="font-bold text-gray-900 dark:text-white">Documents - {selectedSubmission.user}</h3>
              <button
                onClick={() => setSelectedSubmission(null)}
                className="p-2 hover:bg-gray-50 rounded-btn"
              >
                <XCircle className="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </button>
            </div>
            <div className="p-6 space-y-6">
              {Object.entries(selectedSubmission.documents).map(([key, doc]) => (
                doc.uploaded && (
                  <div key={key} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <h4 className="font-semibold text-gray-900 capitalize">{key}</h4>
                      <button className="flex items-center gap-2 text-sm text-green hover:text-green-dark">
                        <Download className="w-4 h-4" />
                        Télécharger
                      </button>
                    </div>
                    <div className="bg-gray-100 rounded-btn h-64 flex items-center justify-center">
                      <p className="text-gray-500 text-sm">Aperçu du document: {doc.url}</p>
                    </div>
                  </div>
                )
              ))}
            </div>
            {selectedSubmission.status === 'pending' && (
              <div className="sticky bottom-0 bg-white border-t border-gray-100/30 px-6 py-4 flex gap-3">
                <button
                  onClick={() => handleApprove(selectedSubmission.id)}
                  className="flex-1 btn-primary flex items-center justify-center gap-2"
                >
                  <CheckCircle className="w-5 h-5" />
                  Approuver
                </button>
                <button
                  onClick={() => handleReject(selectedSubmission.id)}
                  className="flex-1 bg-coral text-white px-5 py-3 rounded-btn font-semibold hover:bg-coral/90 transition-colors flex items-center justify-center gap-2"
                >
                  <XCircle className="w-5 h-5" />
                  Rejeter
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
