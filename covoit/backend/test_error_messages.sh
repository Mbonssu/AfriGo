#!/bin/bash

# Script de test des messages d'erreur d'inscription
# Usage: ./test_error_messages.sh

API_URL="http://192.168.45.54:8000"

echo "🧪 Test des messages d'erreur d'inscription"
echo "============================================"
echo ""

# Test 1: Inscription initiale réussie
echo "📝 Test 1: Inscription initiale (doit réussir)"
RESPONSE=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test@1234",
    "phone": "652141260",
    "role": "passenger"
  }')
echo "$RESPONSE" | grep -o '"email":"[^"]*"' | head -1
echo ""
echo ""

# Test 2: Email déjà utilisé
echo "📝 Test 2: Inscription avec email déjà utilisé"
echo "Message attendu: 'Cet email est déjà utilisé...'"
RESPONSE=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test@1234",
    "phone": "699999999",
    "role": "passenger"
  }')
echo "Réponse: $RESPONSE"
echo ""
echo ""

# Test 3: Téléphone déjà utilisé
echo "📝 Test 3: Inscription avec téléphone déjà utilisé"
echo "Message attendu: 'Ce numéro de téléphone est déjà utilisé...'"
RESPONSE=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "autre@example.com",
    "password": "Test@1234",
    "phone": "652141260",
    "role": "passenger"
  }')
echo "Réponse: $RESPONSE"
echo ""
echo ""

# Test 4: Connexion avec mauvais mot de passe
echo "📝 Test 4: Connexion avec mauvais mot de passe"
echo "Message attendu: 'Email ou mot de passe incorrect.'"
RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "MauvaisMotDePasse"
  }')
echo "Réponse: $RESPONSE"
echo ""
echo ""

echo "============================================"
echo "🎉 Tests terminés"
