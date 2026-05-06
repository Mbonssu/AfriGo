import { useState } from 'react'
import { Lightbulb, ThumbsUp, MessageSquare, Clock, CheckCircle, Star } from 'lucide-react'

const mockSuggestions = [
  {
    id: 1,
    user: 'Marie Ngo',
    title: 'Ajouter un système de notation des trajets',
    description: 'Il serait bien de pouvoir noter chaque trajet individuellement, pas seulement le chauffeur. Cela permettrait de mieux évaluer la qualité du service.',
    category: 'feature',
    votes: 24,
    status: 'under_review',
    createdAt: '2026-05-08 14:30',
    comments: 5,
  },
  {
    id: 2,
    user: 'Paul Mbida',
    title: 'Mode sombre pour l\'application',
    description: 'L\'application est trop lumineuse la nuit. Un mode sombre serait très apprécié.',
    category: 'ui',
    votes: 18,
    status: 'planned',
    createdAt: '2026-05-07 10:15',
    comments: 3,
  },
  {
    id: 3,
    user: 'Sophie Talla',
    title: 'Partage de localisation en temps réel',
    description: 'Pouvoir partager ma position en temps réel avec mes proches pendant le trajet pour plus de sécurité.',
    category: 'feature',
    votes: 42,
    status: 'in_progress',
    createdAt: '2026-05-05 16:45',
    comments: 12,
  },
  {
    id: 4,
    user: 'Eric Fouda',
    title: 'Réduction pour trajets réguliers',
    description: 'Offrir des réductions aux utilisateurs qui font le même trajet régulièrement (ex: domicile-travail).',
    category: 'business',
    votes: 31,
    status: 'under_review',
    createdAt: '2026-05-04 11:30',
    comments: 8,
  },
  {
    id: 5,
    user: 'Alice Biya',
    title: 'Chat entre passagers',
    description: 'Permettre aux passagers d\'un même trajet de communiquer entre eux avant le départ.',
    category: 'feature',
    votes: 15,
    status: 'rejected',
    createdAt: '2026-05-03 09:20',
    rejectionReason: 'Risque de spam et problèmes de modération',
    comments: 7,
  },
  {
    id: 6,
    user: 'David Onana',
    title: 'Programme de fidélité',
    description: 'Système de points pour les utilisateurs réguliers qui peuvent être échangés contre des réductions.',
    category: 'business',
    votes: 56,
    status: 'planned',
    createdAt: '2026-05-02 15:10',
    comments: 18,
  },
]

export default function Suggestions() {
  const [filter, setFilter] = useState('all')
  const [sortBy, setSortBy] = useState('votes')

  const filteredSuggestions = mockSuggestions
    .filter(s => filter === 'all' || s.status === filter)
    .sort((a, b) => {
      if (sortBy === 'votes') return b.votes - a.votes
      if (sortBy === 'recent') return new Date(b.createdAt) - new Date(a.createdAt)
      return 0
    })

  const handleVote = (id) => {
    console.log('Vote pour:', id)
    // TODO: Appel API
  }

  const handleStatusChange = (id, newStatus) => {
    console.log('Changer statut:', id, newStatus)
    // TODO: Appel API
  }

  const getCategoryColor = (category) => {
    switch (category) {
      case 'feature': return 'bg-green-light text-green'
      case 'ui': return 'bg-prime-bg text-prime'
      case 'business': return 'bg-coral-light text-coral'
      default: return 'bg-gray-100 text-gray-600'
    }
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'planned': return 'badge-success'
      case 'in_progress': return 'badge-warning'
      case 'under_review': return 'badge-gray'
      case 'rejected': return 'badge-error'
      default: return 'badge-gray'
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between items-start">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Suggestions</h1>
          <p className="text-gray-600 mt-1">{mockSuggestions.length} suggestions des utilisateurs</p>
        </div>

        <div className="flex gap-2">
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
            className="input py-2"
          >
            <option value="votes">Plus votées</option>
            <option value="recent">Plus récentes</option>
          </select>
        </div>
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
          Toutes ({mockSuggestions.length})
        </button>
        <button
          onClick={() => setFilter('under_review')}
          className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
            filter === 'under_review'
              ? 'bg-gray-600 text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          En examen ({mockSuggestions.filter(s => s.status === 'under_review').length})
        </button>
        <button
          onClick={() => setFilter('planned')}
          className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
            filter === 'planned'
              ? 'bg-green text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Planifiées ({mockSuggestions.filter(s => s.status === 'planned').length})
        </button>
        <button
          onClick={() => setFilter('in_progress')}
          className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
            filter === 'in_progress'
              ? 'bg-prime text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          En cours ({mockSuggestions.filter(s => s.status === 'in_progress').length})
        </button>
        <button
          onClick={() => setFilter('rejected')}
          className={`px-4 py-2 rounded-btn text-sm font-semibold transition-colors ${
            filter === 'rejected'
              ? 'bg-coral text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Rejetées ({mockSuggestions.filter(s => s.status === 'rejected').length})
        </button>
      </div>

      {/* Suggestions List */}
      <div className="space-y-4">
        {filteredSuggestions.map((suggestion) => (
          <div key={suggestion.id} className="card p-6">
            <div className="flex gap-4">
              {/* Vote Section */}
              <div className="flex flex-col items-center gap-2">
                <button
                  onClick={() => handleVote(suggestion.id)}
                  className="w-12 h-12 bg-green-light rounded-xl flex items-center justify-center hover:bg-green hover:text-white transition-colors group"
                >
                  <ThumbsUp className="w-5 h-5 text-green group-hover:text-white" />
                </button>
                <span className="font-bold text-gray-900 dark:text-white">{suggestion.votes}</span>
              </div>

              {/* Content */}
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-4 mb-2">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <span className={`badge ${getCategoryColor(suggestion.category)}`}>
                        {suggestion.category === 'feature' ? 'Fonctionnalité' :
                         suggestion.category === 'ui' ? 'Interface' :
                         suggestion.category === 'business' ? 'Business' :
                         suggestion.category}
                      </span>
                      <span className={`badge ${getStatusColor(suggestion.status)}`}>
                        {suggestion.status === 'planned' ? 'Planifiée' :
                         suggestion.status === 'in_progress' ? 'En cours' :
                         suggestion.status === 'under_review' ? 'En examen' :
                         suggestion.status === 'rejected' ? 'Rejetée' :
                         suggestion.status}
                      </span>
                    </div>
                    <h3 className="font-bold text-gray-900 mb-1">{suggestion.title}</h3>
                    <p className="text-sm text-gray-600 mb-2">Par {suggestion.user}</p>
                  </div>
                </div>

                <p className="text-sm text-gray-700 mb-3">{suggestion.description}</p>

                {suggestion.rejectionReason && (
                  <div className="bg-coral-light border border-coral/20 rounded-btn p-3 mb-3">
                    <p className="text-sm font-semibold text-coral mb-1">Raison du rejet:</p>
                    <p className="text-sm text-gray-700">{suggestion.rejectionReason}</p>
                  </div>
                )}

                <div className="flex items-center gap-4 text-xs text-gray-500 mb-3">
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {suggestion.createdAt}
                  </span>
                  <span className="flex items-center gap-1">
                    <MessageSquare className="w-3 h-3" />
                    {suggestion.comments} commentaires
                  </span>
                </div>

                {/* Admin Actions */}
                <div className="flex gap-2">
                  <select
                    value={suggestion.status}
                    onChange={(e) => handleStatusChange(suggestion.id, e.target.value)}
                    className="input py-2 text-sm"
                  >
                    <option value="under_review">En examen</option>
                    <option value="planned">Planifiée</option>
                    <option value="in_progress">En cours</option>
                    <option value="rejected">Rejetée</option>
                  </select>
                  <button className="btn-secondary text-sm py-2 px-4">
                    Voir les commentaires
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
