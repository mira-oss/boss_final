import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey ='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'; // Remplacez par votre clé API
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> fetchPartnersByMoods(List<String> userMoods) async {
  try {
    final querySnapshot = await _firestore.collection('partenaires').get();
    final partners = querySnapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Convertir les champs Timestamp en String
          if (data['date_creation'] is Timestamp) {
            data['date_creation'] = (data['date_creation'] as Timestamp).toDate().toIso8601String();
          }
          if (data['dernier_mdp_change'] is Timestamp) {
            data['dernier_mdp_change'] = (data['dernier_mdp_change'] as Timestamp).toDate().toIso8601String();
          }

          return data;
        })
        .where((partner) {
          final partnerMoods = List<String>.from(partner['moods'] ?? []);
          return userMoods.any((mood) => partnerMoods.contains(mood));
        })
        .toList();
    return partners;
  } catch (e) {
    print('Erreur lors de la récupération des partenaires: $e');
    throw Exception('Impossible de récupérer les partenaires.');
  }
}

  static Future<Map<String, dynamic>> generateItinerary({
    required String userPrompt,
    required String budget,
    required String location,
    required List<String> userMoods,
  }) async {
    try {
      // Récupérer les partenaires correspondant aux moods
      final matchingPartners = await fetchPartnersByMoods(userMoods);

      // Formater les données des partenaires pour les inclure dans le contexte
      final partnersContext = jsonEncode(matchingPartners);

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
  Vous êtes un assistant de voyage expert pour $location. 
  Voici les données disponibles dans notre base de données : $partnersContext.
  Proposez 3 parcours touristiques détaillés adaptés aux demandes de l'utilisateur avec un budget total de $budget FCFA maximum.

  Chaque parcours doit:
  1. Avoir un nom créatif avec un thème (Ex: "Chill & saveurs", "Ambiance & Culture", "Aventure urbaine")
  2. Inclure 3-4 activités tirées uniquement des données fournies
  3. Pour chaque activité, précisez: l'heure, le nom du lieu (en italique si c'est un commerce), et le prix en FCFA
  4. Être réaliste et varié (gastronomie, culture, loisirs)

  Format de réponse EXACT:
  {
    "options": [
      {
        "name": "Parcours #1 – [Thème]",
        "activities": [
          {"time": "13h30", "activity": "Brunch chez *Mira foods*", "price": "2500"},
          {"time": "15h00", "activity": "Pause chill à la plage Obama", "price": "0"},
          {"time": "17h00", "activity": "Glace artisanale chez *Léonidas*", "price": "1500"}
        ],
        "description": "Description courte du parcours et de son ambiance",
        "totalPrice": "4000"
      },
      {
        "name": "Parcours #2 – [Autre Thème]",
        "activities": [...]
      },
      {
        "name": "Parcours #3 – [Autre Thème]",
        "activities": [...]
      }
    ]
  }
  '''
            },
            {
              'role': 'user',
              'content': userPrompt
            }
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
        throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erreur OpenAI: $e');
      throw Exception('Impossible de générer un itinéraire: $e');
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
              'content': 'Vous êtes un assistant de voyage au Bénin, spécialisé dans le tourisme local.'
            },
            {
              'role': 'user',
              'content': userPrompt
            }
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