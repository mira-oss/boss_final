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
      final matchingPartners = await fetchPartnersByMoods(userMoods);
      
      if (matchingPartners.isEmpty) {
        throw Exception('Aucun restaurant partenaire ne correspond à vos critères.');
      }

      // Encodage des données des partenaires pour éviter les problèmes de caractères spéciaux
      final encodedPartners = matchingPartners.map((partner) => {
        'id': partner['id'],
        'nom': _encodeSpecialChars(partner['nom'] ?? ''),
        'email': partner['email'],
        'phone': partner['phone'],
        'latitude': partner['latitude'],
        'longitude': partner['longitude'],
        'moods': partner['moods'],
        'statut': partner['statut'],
      }).toList();

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
Utilise UNIQUEMENT les restaurants partenaires suivants pour créer exactement 2 parcours différents : ${jsonEncode(encodedPartners)}

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
            {
              'role': 'user',
              'content': _encodeSpecialChars(userPrompt)
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        final parsedResponse = jsonDecode(content);
        
        // Décodage des caractères spéciaux dans la réponse
        return _decodeSpecialCharsInResponse(parsedResponse);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la génération du parcours: $e');
      throw Exception('Impossible de générer un parcours: $e');
    }
  }

  // Fonction pour encoder les caractères spéciaux
  static String _encodeSpecialChars(String text) {
    return text
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), ''); // Supprime les caractères non ASCII
  }

  // Fonction pour décoder la réponse et restaurer les caractères spéciaux
  static Map<String, dynamic> _decodeSpecialCharsInResponse(Map<String, dynamic> response) {
    if (response['parcours'] is List) {
      final parcours = response['parcours'] as List;
      for (var i = 0; i < parcours.length; i++) {
        if (parcours[i]['titre'] is String) {
          parcours[i]['titre'] = _restoreSpecialChars(parcours[i]['titre']);
        }
        if (parcours[i]['description'] is String) {
          parcours[i]['description'] = _restoreSpecialChars(parcours[i]['description']);
        }
        if (parcours[i]['etapes'] is List) {
          for (var etape in parcours[i]['etapes']) {
            if (etape['nom'] is String) {
              etape['nom'] = _restoreSpecialChars(etape['nom']);
            }
            if (etape['description'] is String) {
              etape['description'] = _restoreSpecialChars(etape['description']);
            }
          }
        }
      }
    }
    return response;
  }

  // Fonction pour restaurer les caractères spéciaux courants en français
  static String _restoreSpecialChars(String text) {
    // Dictionnaire de remplacement pour les cas courants
    final Map<String, String> replacements = {
      'cafe': 'café',
      'theatre': 'théâtre',
      'crepe': 'crêpe',
      'patisserie': 'pâtisserie',
      'boulangerie': 'boulangerie',
      'epicerie': 'épicerie',
      'marche': 'marché',
      'hotel': 'hôtel',
      // Ajoutez d'autres remplacements courants si nécessaire
    };

    String result = text;
    replacements.forEach((key, value) {
      result = result.replaceAll(RegExp(key, caseSensitive: false), value);
    });
    return result;
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
