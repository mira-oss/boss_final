import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey =
      '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';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> fetchPartnersByMoods(
      List<String> userMoods) async {
    try {
      final querySnapshot = await _firestore
          .collection('partenaires')
          .where('moods', arrayContainsAny: userMoods)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            // Extraction des coordonnées de localisation
            List<double> coordinates = [];
            if (data['localisation'] != null && data['localisation'] is List) {
              coordinates = (data['localisation'] as List)
                  .map((coord) => double.tryParse(coord.toString()) ?? 0.0)
                  .toList();
            }

            return {
              'id': doc.id,
              'nom': data['nom'] ?? '',
              'email': data['email'] ?? '',
              'phone': data['phone'] ?? '',
              'latitude': coordinates.isNotEmpty ? coordinates[0] : 0.0,
              'longitude': coordinates.length > 1 ? coordinates[1] : 0.0,
              'moods': List<String>.from(data['moods'] ?? []),
              'statut': data['statut'] ?? '',
              'date_creation': data['date_creation'] != null
                  ? (data['date_creation'] as Timestamp)
                      .toDate()
                      .toIso8601String()
                  : null,
            };
          })
          .where((partner) =>
              // Ne retourner que les partenaires avec un statut valide et des coordonnées
              partner['statut'] != null &&
              partner['latitude'] != 0.0 &&
              partner['longitude'] != 0.0)
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des partenaires: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> generateItinerary({
    required String userPrompt,
    required String budget,
    required String location,
    required List<String> userMoods,
  }) async {
    try {
      // Récupérer les restaurants partenaires correspondant aux moods
      final matchingPartners = await fetchPartnersByMoods(userMoods);

      if (matchingPartners.isEmpty) {
        throw Exception(
            'Aucun restaurant partenaire ne correspond à vos critères.');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''
Tu es un assistant spécialisé dans la création d'itinéraires gastronomiques.
Utilise UNIQUEMENT les restaurants partenaires suivants pour créer exactement 2 parcours différents : ${jsonEncode(matchingPartners)}

Instructions importantes:
1. Crée EXACTEMENT 2 parcours différents avec des restaurants différents
2. Chaque parcours doit avoir un thème distinct lié aux moods: ${userMoods.join(', ')}
3. Utilise uniquement les restaurants fournis, ne pas en inventer
4. Pour chaque restaurant, utilise ses coordonnées exactes (latitude/longitude)
5. Organise les restaurants de manière logique selon leur localisation

Format de réponse EXACT:
{
  "parcours": [
    {
      "titre": "Nom créatif du parcours #1",
      "description": "Description de l'expérience gastronomique",
      "etapes": [
        {
          "nom": "Nom du restaurant",
          "phone": "Numéro de téléphone",
          "horaire": "Horaire suggéré",
          "latitude": 0.0,
          "longitude": 0.0,
          "mood": "Ambiance du lieu"
        }
      ]
    },
    {
      "titre": "Nom créatif du parcours #2",
      "description": "Description différente",
      "etapes": [...]
    }
  ]
}'''
            },
            {'role': 'user', 'content': userPrompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        final parsedResponse = jsonDecode(content);
        return parsedResponse;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la génération du parcours: $e');
      throw Exception('Impossible de générer un parcours: $e');
    }
  }

  static Future<String> getAIResponse(String userPrompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Vous êtes un assistant spécialisé dans la recommandation de restaurants au Bénin.'
            },
            {'role': 'user', 'content': userPrompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur OpenAI: $e');
      throw Exception('Impossible d\'obtenir une réponse: $e');
    }
  }
}
