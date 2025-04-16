// lib/data/repositories/review_repository.dart

import 'package:patenaire/data/models/review_model.dart';
import 'package:patenaire/data/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewRepository {
  final FirebaseService _firebaseService;

  ReviewRepository(this._firebaseService);

  Future<List<Review>> getReviews(String establishmentId) async {
    try {
      final snapshot =
          await _firebaseService.firestore
              .collection('reviews')
              .where('establishmentId', isEqualTo: establishmentId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        // Créer un Map avec l'ID inclus
        final data = doc.data();
        data['id'] = doc.id; // Ajouter l'ID au Map
        return Review.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<Review> getReviewById(String reviewId) async {
    try {
      final doc =
          await _firebaseService.firestore
              .collection('reviews')
              .doc(reviewId)
              .get();

      if (!doc.exists) {
        throw Exception('Review not found');
      }

      final data = doc.data()!;
      data['id'] = doc.id; // Ajouter l'ID au Map
      return Review.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch review details: $e');
    }
  }

  Future<void> respondToReview(String reviewId, String response) async {
    try {
      await _firebaseService.firestore
          .collection('reviews')
          .doc(reviewId)
          .update({
            'response': response,
            'respondedAt': FieldValue.serverTimestamp(),
            'hasResponse': true,
          });
    } catch (e) {
      throw Exception('Failed to respond to review: $e');
    }
  }

  Future<Map<String, dynamic>> getReviewStatistics(
    String establishmentId,
  ) async {
    try {
      final snapshot =
          await _firebaseService.firestore
              .collection('reviews')
              .where('establishmentId', isEqualTo: establishmentId)
              .get();

      final reviews =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Review.fromJson(data);
          }).toList();

      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
        };
      }

      // Calculate average rating
      double sum = 0;
      Map<String, int> distribution = {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0};

      for (var review in reviews) {
        sum += review.rating;
        distribution[review.rating.toString()] =
            (distribution[review.rating.toString()] ?? 0) + 1;
      }

      double average = sum / reviews.length;

      return {
        'averageRating': average,
        'totalReviews': reviews.length,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      throw Exception('Failed to get review statistics: $e');
    }
  }
}
