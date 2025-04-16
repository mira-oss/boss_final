class FormValidators {
  // Validation d'email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre adresse email';
    }

    // Regex pour validation basique d'email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide';
    }

    return null;
  }

  // Validation de mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }

    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    return null;
  }

  // Validation de confirmation de mot de passe
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  // Validation de numéro de téléphone
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }

    // Regex pour validation basique de numéro de téléphone français
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{8,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Veuillez entrer un numéro de téléphone valide';
    }

    return null;
  }

  // Validation de champ obligatoire
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? 'Le champ $fieldName est obligatoire'
          : 'Ce champ est obligatoire';
    }

    return null;
  }

  // Validation de nom
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est obligatoire';
    }

    if (value.length < 2) {
      return 'Doit contenir au moins 2 caractères';
    }

    return null;
  }

  // Validation de site web
  static String? validateWebsite(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Le site web n'est pas obligatoire
    }

    String url = value.toLowerCase();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(url)) {
      return 'Veuillez entrer une URL valide';
    }

    return null;
  }

  // Validation de code postal français
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code postal est obligatoire';
    }

    // Regex pour code postal français (5 chiffres)
    final postalCodeRegex = RegExp(r'^[0-9]{5}$');
    if (!postalCodeRegex.hasMatch(value)) {
      return 'Le code postal doit contenir 5 chiffres';
    }

    return null;
  }

  // Validation de numéro SIRET
  static String? validateSiret(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro SIRET est obligatoire';
    }

    // Formatage: retirer les espaces et tirets
    String cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');

    // Longueur du SIRET: 14 chiffres
    if (cleanValue.length != 14 ||
        !RegExp(r'^[0-9]{14}$').hasMatch(cleanValue)) {
      return 'Le numéro SIRET doit contenir 14 chiffres';
    }

    // Algorithme de validation du SIRET (Luhn)
    int sum = 0;
    for (int i = 0; i < 14; i++) {
      int digit = int.parse(cleanValue[i]);
      if (i % 2 == 0) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }

    if (sum % 10 != 0) {
      return 'Numéro SIRET invalide';
    }

    return null;
  }

  // Validation de numéro TVA intracommunautaire
  static String? validateVatNumber(String? value, {bool isRequired = false}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Le numéro de TVA est obligatoire' : null;
    }

    // Format basique pour n° TVA FR: FR + 2 chiffres + 9 chiffres (SIREN)
    final vatRegex = RegExp(r'^FR[0-9]{11}$');
    if (!vatRegex.hasMatch(value.replaceAll(RegExp(r'\s'), ''))) {
      return 'Format invalide (ex: FR12345678901)';
    }

    return null;
  }

  // Validation de date
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La date est obligatoire';
    }

    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();

      if (date.isAfter(now)) {
        return 'La date ne peut pas être dans le futur';
      }
    } catch (e) {
      return 'Format de date invalide';
    }

    return null;
  }

  // Validation de longueur minimale
  static String? validateMinLength(
    String? value,
    int minLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return null; // Déléguer à validateRequired si nécessaire
    }

    if (value.length < minLength) {
      return fieldName != null
          ? 'Le champ $fieldName doit contenir au moins $minLength caractères'
          : 'Ce champ doit contenir au moins $minLength caractères';
    }

    return null;
  }

  // Validation de longueur maximale
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return null; // Déléguer à validateRequired si nécessaire
    }

    if (value.length > maxLength) {
      return fieldName != null
          ? 'Le champ $fieldName ne doit pas dépasser $maxLength caractères'
          : 'Ce champ ne doit pas dépasser $maxLength caractères';
    }

    return null;
  }
}
