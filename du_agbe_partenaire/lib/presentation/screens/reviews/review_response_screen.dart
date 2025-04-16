// lib/presentation/screens/reviews/review_response_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/data/models/review_model.dart';
import 'package:patenaire/data/repositories/review_repository.dart';
import 'package:patenaire/presentation/common_widgets/custom_button.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';

class ReviewResponseScreen extends StatefulWidget {
  final String reviewId;

  const ReviewResponseScreen({Key? key, required this.reviewId})
    : super(key: key);

  @override
  _ReviewResponseScreenState createState() => _ReviewResponseScreenState();
}

class _ReviewResponseScreenState extends State<ReviewResponseScreen> {
  late ReviewRepository _reviewRepository;
  Review? _review;
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
        title: const Text('Répondre à l\'avis'),
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
                    _buildReviewSummary(),
                    const SizedBox(height: 24),
                    _buildResponseForm(),
                  ],
                ),
              ),
    );
  }

  Widget _buildReviewSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _review!.customerName.isNotEmpty
                    ? _review!.customerName
                    : 'Anonyme',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _review!.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_review!.comment),
        ],
      ),
    );
  }

  Widget _buildResponseForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre réponse', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: _responseController,
            decoration: const InputDecoration(
              hintText: 'Rédigez votre réponse ici...',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir une réponse';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator())
          else
            CustomButton(
              text: _review?.hasResponse == true ? 'Mettre à jour' : 'Répondre',
              onPressed: _submitResponse,
              backgroundColor: ColorConstants.primaryColor,
              width: double.infinity,
            ),
        ],
      ),
    );
  }
}
