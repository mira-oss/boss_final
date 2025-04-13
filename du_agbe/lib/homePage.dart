import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final List<Map<String, dynamic>> categories = [
    {"icon": FontAwesomeIcons.utensils, "label": "Restaurants", "color": Colors.red},
    {"icon": FontAwesomeIcons.shoppingBag, "label": "Shopping", "color": Colors.blue},
    {"icon": FontAwesomeIcons.umbrellaBeach, "label": "Plages", "color": Colors.teal},
    {"icon": FontAwesomeIcons.music, "label": "Événements", "color": Colors.purple},
    {"icon": FontAwesomeIcons.mugHot, "label": "Cafés", "color": Colors.brown},
    {"icon": FontAwesomeIcons.landmark, "label": "Culture", "color": Colors.orange},
  ];
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _text = '';
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _checkPermissionAndInitSpeech();
  }
  
  // Vérifier les permissions et initialiser le système de reconnaissance vocale
  Future<void> _checkPermissionAndInitSpeech() async {
    try {
      // Demander la permission du microphone dès le démarrage
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        setState(() => _errorMessage = 'Permission microphone nécessaire pour utiliser cette fonctionnalité');
        return;
      }
      
      // Initialiser le système de reconnaissance vocale
      _initSpeech();
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de la vérification des permissions: $e');
    }
  }

  // Initialiser le système de reconnaissance vocale
  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) => setState(() {
          _errorMessage = 'Erreur: ${error.errorMsg}';
          _isListening = false;
        }),
      );
      setState(() => _speechEnabled = available);
      if (!available) {
        setState(() => _errorMessage = 'La reconnaissance vocale n\'est pas disponible sur cet appareil');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur d\'initialisation: $e');
    }
  }

  // Démarrer ou arrêter l'écoute
  Future<void> _listen() async {
    // Vérifier si l'initialisation a réussi
    if (!_speechEnabled) {
      setState(() => _errorMessage = 'La reconnaissance vocale n\'est pas disponible');
      return;
    }

    // Vérifier à nouveau la permission du microphone
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        setState(() => _errorMessage = 'Permission microphone refusée');
        return;
      }
    }

    // Arrêter l'écoute si elle est en cours
    if (_isListening) {
      try {
        _speech.stop();
        setState(() => _isListening = false);
      } catch (e) {
        setState(() => _errorMessage = 'Erreur lors de l\'arrêt: $e');
      }
    } else {
      // Démarrer l'écoute
      try {
        setState(() {
          _isListening = true;
          _errorMessage = '';
        });
        
        // Effacer le texte précédent lors d'une nouvelle écoute
        setState(() => _text = '');
        
        await _speech.listen(
          onResult: (result) => setState(() {
            _text = result.recognizedWords;
            if (result.finalResult) {
              _isListening = false;
            }
          }),
          localeId: 'fr_FR', // Spécifier la langue française
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 3),
          cancelOnError: true,
          partialResults: true,
          listenMode: stt.ListenMode.confirmation,
        );
      } catch (e) {
        setState(() {
          _isListening = false;
          _errorMessage = 'Erreur d\'écoute: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec avatar
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/images/avatar.jpeg'),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello,", style: TextStyle(fontSize: 16)),
                      Text("Prêt pour une belle journée ?", 
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 30),
              
              // Barre de recherche
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _text),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Parlez maintenant...' : 'Dites-nous ce que vous voulez...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: _listen,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : 
                               _speechEnabled ? Colors.orange : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              
              if (_text.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  'Vous avez dit :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_text),
                ),
              ],
              
              SizedBox(height: 30),
              
              // Titre section catégories
              Text("Catégories", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              
              SizedBox(height: 15),
              
              // Liste horizontale des catégories
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: categories[index]["color"]!.withOpacity(0.2),
                            child: Icon(
                              categories[index]["icon"],
                              color: categories[index]["color"],
                              size: 24,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            categories[index]["label"],
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}