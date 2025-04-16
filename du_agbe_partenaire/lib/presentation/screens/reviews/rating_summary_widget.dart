// lib/presentation/screens/reviews/rating_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:patenaire/core/constants/color_constants.dart';

class RatingSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const RatingSummaryWidget({Key? key, required this.statistics})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '${statistics['averageRating'].toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStarRating(statistics['averageRating']),
                  const SizedBox(height: 4),
                  Text(
                    '${statistics['totalReviews']} avis',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRatingBars(context),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isHalf = index < rating && index + 1 > rating;
        final isFull = index < rating.floor();

        return Icon(
          isHalf ? Icons.star_half : (isFull ? Icons.star : Icons.star_border),
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildRatingBars(BuildContext context) {
    Map<String, int> distribution = statistics['ratingDistribution'];
    int totalReviews = statistics['totalReviews'];

    return Column(
      children:
          [5, 4, 3, 2, 1].map((rating) {
            final count = distribution[rating.toString()] ?? 0;
            final percent = totalReviews > 0 ? count / totalReviews : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('$rating'),
                  const SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorConstants.primaryColor,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count'),
                ],
              ),
            );
          }).toList(),
    );
  }
}
