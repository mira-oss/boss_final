// lib/presentation/screens/reviews/reviews_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/data/models/review_model.dart';
import 'package:patenaire/data/repositories/review_repository.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/presentation/state/establishment_provider.dart';
import 'package:patenaire/presentation/screens/reviews/rating_summary_widget.dart';

class ReviewsListScreen extends StatefulWidget {
  const ReviewsListScreen({Key? key}) : super(key: key);

  @override
  _ReviewsListScreenState createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  late ReviewRepository _reviewRepository;
  List<Review> _reviews = [];
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {
    'averageRating': 0.0,
    'totalReviews': 0,
    'ratingDistribution': {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
  };

  @override
  void initState() {
    super.initState();
    _reviewRepository = Provider.of<ReviewRepository>(context, listen: false);
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final establishmentId =
          Provider.of<EstablishmentProvider>(
            context,
            listen: false,
          ).currentEstablishment!.id;

      _reviews = await _reviewRepository.getReviews(establishmentId);
      _statistics = await _reviewRepository.getReviewStatistics(
        establishmentId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        // lib/presentation/screens/reviews/reviews_list_screen.dart (suite)
        SnackBar(
          content: Text('Erreur lors du chargement des avis: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avis clients'),
        backgroundColor: ColorConstants.primaryColor,
      ),
      body:
          _isLoading
              ? const LoadingIndicator()
              : RefreshIndicator(
                onRefresh: _loadReviews,
                child: Column(
                  children: [
                    RatingSummaryWidget(statistics: _statistics),
                    Expanded(
                      child:
                          _reviews.isEmpty
                              ? Center(
                                child: Text(
                                  'Aucun avis pour le moment',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              )
                              : ListView.builder(
                                itemCount: _reviews.length,
                                itemBuilder: (context, index) {
                                  final review = _reviews[index];
                                  return ReviewCard(
                                    review: review,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/review-details',
                                        arguments: review.id,
                                      ).then((_) => _loadReviews());
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onTap;

  const ReviewCard({Key? key, required this.review, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ColorConstants.primaryColor,
                    child: Text(
                      review.customerName.isNotEmpty
                          ? review.customerName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.customerName.isNotEmpty
                              ? review.customerName
                              : 'Anonyme',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(review.rating.toString()),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(review.comment),
              if (review.hasResponse) ...[
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Votre réponse:',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(review.response ?? ''),
                    ],
                  ),
                ),
              ],
              if (!review.hasResponse) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: onTap,
                    child: const Text('Répondre'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
