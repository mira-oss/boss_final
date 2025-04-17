import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fl_chart/fl_chart.dart';

// Modèle pour les avis
class Review {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime date;
  String? response;
  final bool isResponded;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.date,
    this.response,
    required this.isResponded,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Client anonyme',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      response: data['response'],
      isResponded: data['isResponded'] ?? false,
    );
  }
}

// Provider pour la gestion des avis
class ReviewsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Review> _reviews = [];
  bool _isLoading = true;
  String _filter = 'all';
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String get filter => _filter;
  double get averageRating => _averageRating;
  Map<int, int> get ratingDistribution => _ratingDistribution;

  // Initialiser et récupérer les avis
  Future<void> fetchReviews() async {
    _isLoading = true;
    notifyListeners();

    try {
      String? establishmentId = _auth.currentUser?.uid;
      if (establishmentId == null) return;

      QuerySnapshot snapshot =
          await _firestore
              .collection('establishments')
              .doc(establishmentId)
              .collection('reviews')
              .orderBy('date', descending: true)
              .get();

      _reviews = snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
      _calculateStatistics();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la récupération des avis: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Répondre à un avis
  Future<void> respondToReview(String reviewId, String response) async {
    try {
      String? establishmentId = _auth.currentUser?.uid;
      if (establishmentId == null) return;

      await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .collection('reviews')
          .doc(reviewId)
          .update({'response': response, 'isResponded': true});

      // Mettre à jour la liste locale
      int index = _reviews.indexWhere((review) => review.id == reviewId);
      if (index != -1) {
        _reviews[index] = Review(
          id: _reviews[index].id,
          userId: _reviews[index].userId,
          userName: _reviews[index].userName,
          userPhotoUrl: _reviews[index].userPhotoUrl,
          rating: _reviews[index].rating,
          comment: _reviews[index].comment,
          date: _reviews[index].date,
          response: response,
          isResponded: true,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la réponse à l\'avis: $e');
    }
  }

  // Signaler un avis inapproprié
  Future<void> reportReview(String reviewId) async {
    try {
      String? establishmentId = _auth.currentUser?.uid;
      if (establishmentId == null) return;

      await _firestore.collection('reported_reviews').add({
        'reviewId': reviewId,
        'establishmentId': establishmentId,
        'reportedAt': Timestamp.now(),
        'status': 'pending',
      });
    } catch (e) {
      print('Erreur lors du signalement de l\'avis: $e');
    }
  }

  // Définir le filtre
  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  // Calculer les statistiques
  void _calculateStatistics() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
      _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      return;
    }

    double total = 0;
    _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var review in _reviews) {
      total += review.rating;
      int ratingKey = review.rating.round();
      if (_ratingDistribution.containsKey(ratingKey)) {
        _ratingDistribution[ratingKey] =
            (_ratingDistribution[ratingKey] ?? 0) + 1;
      }
    }

    _averageRating = total / _reviews.length;
  }

  // Filtrer les avis selon le critère
  List<Review> getFilteredReviews() {
    switch (_filter) {
      case 'unresponded':
        return _reviews.where((review) => !review.isResponded).toList();
      case 'responded':
        return _reviews.where((review) => review.isResponded).toList();
      case 'positive':
        return _reviews.where((review) => review.rating >= 4).toList();
      case 'negative':
        return _reviews.where((review) => review.rating < 3).toList();
      default:
        return _reviews;
    }
  }
}

// Page principale des avis
class ReviewsPage extends StatefulWidget {
  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  late ReviewsProvider _reviewsProvider;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _reviewsProvider = Provider.of<ReviewsProvider>(context, listen: false);
    _reviewsProvider.fetchReviews();

    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Avis Clients',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _reviewsProvider.fetchReviews(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Tous les avis'), Tab(text: 'Statistiques')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReviewsTab(), _buildStatisticsTab()],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Consumer<ReviewsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final filteredReviews =
            provider.getFilteredReviews().where((review) {
              if (_searchTerm.isEmpty) return true;
              return review.comment.toLowerCase().contains(
                    _searchTerm.toLowerCase(),
                  ) ||
                  review.userName.toLowerCase().contains(
                    _searchTerm.toLowerCase(),
                  );
            }).toList();

        return Column(
          children: [
            _buildSearchAndFilters(provider),
            Expanded(
              child:
                  filteredReviews.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun avis trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: filteredReviews.length,
                        itemBuilder: (context, index) {
                          return _buildReviewCard(
                            filteredReviews[index],
                            provider,
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters(ReviewsProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les avis...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tous', provider),
                SizedBox(width: 8),
                _buildFilterChip('unresponded', 'Sans réponse', provider),
                SizedBox(width: 8),
                _buildFilterChip('responded', 'Répondus', provider),
                SizedBox(width: 8),
                _buildFilterChip('positive', 'Positifs', provider),
                SizedBox(width: 8),
                _buildFilterChip('negative', 'Négatifs', provider),
              ],
            ),
          ),
          SizedBox(height: 8),
          provider.reviews.isNotEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Note moyenne: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      provider.averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _getRatingColor(provider.averageRating),
                      ),
                    ),
                    SizedBox(width: 8),
                    RatingBar.builder(
                      initialRating: provider.averageRating,
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 18,
                      ignoreGestures: true,
                      itemBuilder:
                          (context, _) => Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (_) {},
                    ),
                    SizedBox(width: 8),
                    Text(
                      '(${provider.reviews.length} avis)',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    ReviewsProvider provider,
  ) {
    final isSelected = provider.filter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        provider.setFilter(selected ? value : 'all');
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
      backgroundColor: Colors.grey[200],
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  // Dans votre fichier Avis_interactions.dart, remplacez le Widget _buildReviewCard avec ce code corrigé:

  Widget _buildReviewCard(Review review, ReviewsProvider provider) {
    final TextEditingController responseController = TextEditingController();
    if (review.response != null) {
      responseController.text = review.response!;
    }

    return Slidable(
      // Nouvelle syntaxe pour flutter_slidable
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Signaler cet avis?'),
                      content: Text(
                        'Voulez-vous signaler cet avis comme inapproprié? Notre équipe l\'examinera.',
                      ),
                      actions: [
                        TextButton(
                          child: Text('Annuler'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: Text('Signaler'),
                          onPressed: () {
                            provider.reportReview(review.id);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Avis signalé')),
                            );
                          },
                        ),
                      ],
                    ),
              );
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.flag,
            label: 'Signaler',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        review.userPhotoUrl.isNotEmpty
                            ? NetworkImage(review.userPhotoUrl)
                            : null,
                    child:
                        review.userPhotoUrl.isEmpty
                            ? Text(review.userName[0].toUpperCase())
                            : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(review.date),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.rating.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _getRatingColor(review.rating),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                        ],
                      ),
                      if (!review.isResponded)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'À traiter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(review.comment, style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              if (review.isResponded && review.response != null)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Votre réponse:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(review.response!),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  icon: Icon(Icons.reply),
                  label: Text('Répondre'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                            left: 16,
                            right: 16,
                            top: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Répondre à l\'avis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              TextField(
                                controller: responseController,
                                decoration: InputDecoration(
                                  hintText: 'Votre réponse...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 5,
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    child: Text('Annuler'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  SizedBox(width: 16),
                                  ElevatedButton(
                                    child: Text('Envoyer'),
                                    onPressed: () {
                                      if (responseController.text.isNotEmpty) {
                                        provider.respondToReview(
                                          review.id,
                                          responseController.text,
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatisticsTab() {
    return Consumer<ReviewsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune donnée à afficher',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Satisfaction Client',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _getSatisfactionColor(
                              provider.averageRating,
                            ),
                            child: Text(
                              provider.averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getSatisfactionLabel(provider.averageRating),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getSatisfactionColor(
                                      provider.averageRating,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${provider.reviews.length} avis au total',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${provider.reviews.where((r) => !r.isResponded).length} avis en attente de réponse',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribution des notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: 200,
                        child: _buildRatingDistributionChart(provider),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conseils d\'amélioration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildImprovementTips(provider),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comment répondre aux avis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Répondez rapidement (moins de 24h)'),
                      ),
                      ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Remerciez le client pour son retour'),
                      ),
                      ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Personnalisez chaque réponse'),
                      ),
                      ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text(
                          'Pour les avis négatifs, proposez une solution',
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Invitez le client à revenir'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingDistributionChart(ReviewsProvider provider) {
    // Préparer les données
    final ratingData =
        provider.ratingDistribution.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final rating = ratingData[groupIndex].key;
              final count = ratingData[groupIndex].value;
              return BarTooltipItem(
                '$count avis\n$rating étoiles',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}⭐',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString());
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1);
          },
        ),
        barGroups:
            ratingData.map((entry) {
              final rating = entry.key;
              final count = entry.value;

              Color getBarColor() {
                if (rating >= 4) return Colors.green;
                if (rating >= 3) return Colors.orange;
                return Colors.red;
              }

              return BarChartGroupData(
                x: rating,
                barRods: [
                  BarChartRodData(
                    toY: count.toDouble(),
                    color: getBarColor(),
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: provider.reviews.length.toDouble(),
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildImprovementTips(ReviewsProvider provider) {
    if (provider.averageRating >= 4.5) {
      return ListTile(
        leading: Icon(Icons.thumb_up, color: Colors.green),
        title: Text('Excellente note !'),
        subtitle: Text(
          'Continuez comme ça et encouragez vos clients satisfaits à partager leur expérience.',
        ),
      );
    } else if (provider.averageRating >= 4.0) {
      return Column(
        children: [
          ListTile(
            leading: Icon(Icons.lightbulb_outline, color: Colors.amber),
            title: Text('Bonne note, mais amélioration possible'),
            subtitle: Text(
              'Analysez les avis 4 étoiles pour passer à 5 étoiles.',
            ),
          ),
        ],
      );
    } else if (provider.averageRating >= 3.0) {
      return Column(
        children: [
          ListTile(
            leading: Icon(Icons.error_outline, color: Colors.orange),
            title: Text('Des points à améliorer'),
            subtitle: Text(
              'Concentrez-vous sur les avis négatifs pour identifier les problèmes récurrents.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.chat_bubble_outline, color: Colors.blue),
            title: Text('Répondez à tous les avis'),
            subtitle: Text(
              'Montrez que vous êtes à l\'écoute et prêt à vous améliorer.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.update, color: Colors.purple),
            title: Text('Mettez à jour votre offre'),
            subtitle: Text(
              'Informez vos clients des améliorations réalisées suite à leurs commentaires.',
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text('Action urgente requise'),
            subtitle: Text(
              'Votre note est préoccupante. Examinez attentivement chaque critique.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.support_agent, color: Colors.red),
            title: Text('Formation du personnel'),
            subtitle: Text(
              'Revoyez la qualité de service et formez votre équipe si nécessaire.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.fact_check, color: Colors.red),
            title: Text('Plan d\'action'),
            subtitle: Text(
              'Établissez un plan d\'amélioration concret avec des objectifs mesurables.',
            ),
          ),
        ],
      );
    }
  }

  Color _getSatisfactionColor(double rating) {
    if (rating >= 4.5) return Colors.green[800]!;
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getSatisfactionLabel(double rating) {
    if (rating >= 4.5) return 'Excellente';
    if (rating >= 4.0) return 'Très bonne';
    if (rating >= 3.5) return 'Bonne';
    if (rating >= 3.0) return 'Moyenne';
    if (rating >= 2.0) return 'Faible';
    return 'Critique';
  }
}

// Widget principal à exporter
class AvisInteractionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReviewsProvider(),
      child: ReviewsPage(),
    );
  }
}
