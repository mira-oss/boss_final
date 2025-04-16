// lib/presentation/screens/reviews/review_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/data/models/review_model.dart'; // Import correct
import 'package:patenaire/data/repositories/review_repository.dart';
import 'package:patenaire/presentation/common_widgets/custom_button.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';

class ReviewDetailsScreen extends StatefulWidget {
  final String reviewId;

  const ReviewDetailsScreen({Key? key, required this.reviewId})
    : super(key: key);

  @override
  _ReviewDetailsScreenState createState() => _ReviewDetailsScreenState();
}

class _ReviewDetailsScreenState extends State<ReviewDetailsScreen> {
  late ReviewRepository _reviewRepository;
  Review? _review; // Changé de ReviewModel à Review
  bool _isLoading = true;
  bool _isSubmitting = false;
  final _responseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _reviewRepository = Provider.of<ReviewRepository>(context, listen: false);
    _loadReview();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadReview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _review = await _reviewRepository.getReviewById(widget.reviewId);
      if (_review!.response != null) {
        _responseController.text = _review!.response!;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement de l\'avis: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reviewRepository.respondToReview(
        widget.reviewId,
        _responseController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réponse envoyée avec succès')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l\'envoi de la réponse: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'avis'),
        backgroundColor: ColorConstants.primaryColor,
      ),
      body:
          _isLoading
              ? const LoadingIndicator()
              : _review == null
              ? const Center(child: Text('Avis non trouvé'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReviewCard(),
                    const SizedBox(height: 24),
                    _buildResponseForm(),
                  ],
                ),
              ),
    );
  }

  Widget _buildReviewCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorConstants.primaryColor,
                  child: Text(
                    _review!
                            .customerName
                            .isNotEmpty // Modifié de userName à customerName
                        ? _review!.customerName[0].toUpperCase()
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
                        _review!
                                .customerName
                                .isNotEmpty // Modifié de userName à customerName
                            ? _review!.customerName
                            : 'Anonyme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_review!.createdAt.day}/${_review!.createdAt.month}/${_review!.createdAt.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _review!.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _review!.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseForm() {
    final bool hasResponse = _review!.response != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre réponse', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _responseController,
            decoration: const InputDecoration(
              hintText: 'Écrivez votre réponse à cet avis...',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            enabled: !hasResponse || _review!.response != null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir une réponse';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator())
          else
            CustomButton(
              text:
                  hasResponse
                      ? 'Mettre à jour'
                      : 'Répondre', // Modifié de label à text
              onPressed: _submitResponse,
              backgroundColor: ColorConstants.primaryColor,
              width: double.infinity, // Utilisé width au lieu de isFullWidth
            ),
        ],
      ),
    );
  }
}
