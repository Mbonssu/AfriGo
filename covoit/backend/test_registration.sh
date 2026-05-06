#!/bin/bash

# Script de test d'inscription et de mise à jour du profil
# Usage: ./test_registration.sh

API_URL="http://192.168.45.54:8000"

echo "🧪 Test d'inscription et de mise à jour du profil"
echo "=================================================="
echo ""

# Test 1: Inscription passager
echo "📝 Test 1: Inscription passager"
RESPONSE=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.passager@example.com",
    "password": "Test@1234",
    "phone": "652141260",
    "role": "passenger"
  }')

echo "Réponse: $RESPONSE"
echo ""

# Extraire l'user_id et le token
USER_ID=$(echo $RESPONSE | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
TOKEN=$(echo $RESPONSE | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$USER_ID" ]; then
  echo "❌ Échec de l'inscription"
  exit 1
fi

echo "✅ Inscription réussie"
echo "   User ID: $USER_ID"
echo "   Token: ${TOKEN:0:20}..."
echo ""

# Test 2: Mise à jour du profil
echo "📝 Test 2: Mise à jour du profil utilisateur"
PROFILE_RESPONSE=$(curl -s -X PATCH "$API_URL/api/users/profile/$USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "first_name": "Jean",
    "last_name": "Mbarga"
  }')

echo "Réponse: $PROFILE_RESPONSE"
echo ""

# Test 3: Récupération du profil
echo "📝 Test 3: Récupération du profil"
GET_PROFILE=$(curl -s -X GET "$API_URL/api/users/profile/$USER_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "Réponse: $GET_PROFILE"
echo ""

# Vérifier si first_name et last_name sont présents
if echo "$GET_PROFILE" | grep -q '"first_name":"Jean"'; then
  echo "✅ Profil mis à jour avec succès"
else
  echo "❌ Échec de la mise à jour du profil"
fi

echo ""
echo "=================================================="
echo "🎉 Tests terminés"
