import { Save, Bell, Shield, Database, Mail } from 'lucide-react'

export default function Settings() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Paramètres</h1>
        <p className="text-gray-600 mt-1">Configuration de la plateforme</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Général */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-green-light rounded-xl flex items-center justify-center">
              <Shield className="w-5 h-5 text-green" />
            </div>
            <h3 className="font-bold text-gray-900 dark:text-white">Général</h3>
          </div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Nom de la plateforme
              </label>
              <input type="text" defaultValue="AfriGo" className="input" />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Email de contact
              </label>
              <input type="email" defaultValue="contact@afrigo.cm" className="input" />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Téléphone
              </label>
              <input type="tel" defaultValue="+237 690 000 000" className="input" />
            </div>
          </div>
        </div>

        {/* Notifications */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-prime-bg rounded-xl flex items-center justify-center">
              <Bell className="w-5 h-5 text-prime" />
            </div>
            <h3 className="font-bold text-gray-900 dark:text-white">Notifications</h3>
          </div>
          <div className="space-y-4">
            <label className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-900 dark:text-white">Notifications email</span>
              <input type="checkbox" defaultChecked className="w-5 h-5 text-green rounded" />
            </label>
            <label className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-900 dark:text-white">Notifications SMS</span>
              <input type="checkbox" defaultChecked className="w-5 h-5 text-green rounded" />
            </label>
            <label className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-900 dark:text-white">Alertes admin</span>
              <input type="checkbox" defaultChecked className="w-5 h-5 text-green rounded" />
            </label>
          </div>
        </div>

        {/* Paiements */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-green-light rounded-xl flex items-center justify-center">
              <Database className="w-5 h-5 text-green" />
            </div>
            <h3 className="font-bold text-gray-900 dark:text-white">Paiements</h3>
          </div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Commission (%)
              </label>
              <input type="number" defaultValue="10" className="input" />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Caution (FCFA)
              </label>
              <input type="number" defaultValue="500" className="input" />
            </div>
            <label className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-900 dark:text-white">Mode test</span>
              <input type="checkbox" className="w-5 h-5 text-green rounded" />
            </label>
          </div>
        </div>

        {/* Email */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-prime-bg rounded-xl flex items-center justify-center">
              <Mail className="w-5 h-5 text-prime" />
            </div>
            <h3 className="font-bold text-gray-900 dark:text-white">Configuration Email</h3>
          </div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Serveur SMTP
              </label>
              <input type="text" defaultValue="smtp.gmail.com" className="input" />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Port
              </label>
              <input type="number" defaultValue="587" className="input" />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Email expéditeur
              </label>
              <input type="email" defaultValue="noreply@afrigo.cm" className="input" />
            </div>
          </div>
        </div>
      </div>

      <div className="flex justify-end">
        <button className="btn-primary flex items-center gap-2">
          <Save className="w-5 h-5" />
          Enregistrer les modifications
        </button>
      </div>
    </div>
  )
}
