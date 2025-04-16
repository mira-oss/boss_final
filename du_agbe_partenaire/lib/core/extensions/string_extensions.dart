import 'package:intl/intl.dart';

extension StringExtensions on String {
  // Capitaliser la première lettre
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  // Capitaliser chaque mot
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  // Vérifier si c'est un email valide
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  // Vérifier si c'est un numéro de téléphone valide (format français)
  bool get isValidPhone {
    return RegExp(r'^(0|\+33|0033)[1-9]([-. ]?[0-9]{2}){4}$').hasMatch(this);
  }

  // Formater un numéro de téléphone
  String formatPhone() {
    if (!isValidPhone) return this;

    // Nettoyer le numéro
    var clean = replaceAll(RegExp(r'[^\d+]'), '');

    // Gérer les différents formats (+33, 0033, 0)
    if (clean.startsWith('+33')) {
      clean = '0${clean.substring(3)}';
    } else if (clean.startsWith('0033')) {
      clean = '0${clean.substring(4)}';
    }

    // Formater XX XX XX XX XX
    if (clean.length == 10) {
      return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, 6)} '
          '${clean.substring(6, 8)} ${clean.substring(8, 10)}';
    }

    return this;
  }

  // Convertir en double avec gestion de format français (virgule)
  double? toDouble() {
    if (isEmpty) return null;

    try {
      // Remplacer la virgule par un point pour le parsing
      final normalized = replaceAll(',', '.');
      return double.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  // Convertir en date
  DateTime? toDateTime({String format = 'dd/MM/yyyy'}) {
    if (isEmpty) return null;

    try {
      return DateFormat(format).parse(this);
    } catch (e) {
      return null;
    }
  }

  // Limiter le texte avec des points de suspension
  String limitLength(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  // Enlever les accents
  String removeAccents() {
    const withAccents =
        'àáâäæãåāăąçćčđďèéêëēėęěğǵḧîïíīįìłḿñńǹňôöòóœøōõőṕŕřßśšşșťțûüùúūǘůűųẃẍÿýžźż';
    const withoutAccents =
        'aaaaaaaaaacccddeeeeeeeegghiiiiiilmnnnnooooooooprrsssssttuuuuuuuuuwxyyzzz';

    String result = this;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  // Convertir en slug (pour URLs)
  String toSlug() {
    return removeAccents()
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  // Extraire les initiales (2 premières lettres de chaque mot)
  String get initials {
    if (isEmpty) return '';

    final words = trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, words[0].length > 1 ? 2 : 1).toUpperCase();
    }

    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join('')
        .toUpperCase();
  }
}
