import 'package:du_agbe/pageSuccesss.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kkiapay_flutter_sdk/kkiapay_flutter_sdk.dart'; // Import pour de belles polices
import 'package:intl/intl.dart';
class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSoldeDisponible(context),
            SizedBox(height: 20.0),
            _buildResumeCommande(context),
            SizedBox(height: 20.0),
            _buildModePaiement(context),
            SizedBox(height: 20.0),
            _buildPaiementSolde(context),
            SizedBox(height: 32.0),
            _buildPayButtons(context),
            SizedBox(height: 24.0),
            _buildSecuriteFooter(context),
          ],
        ),
      ),
    );
  }

  // AppBar personnalisé
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
        onPressed: () {
          // Handle back button press
        },
      ),
      title: Text(
        'Paiement',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text(
            'Étape 3/3',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0, // Supprimer l'ombre par défaut de l'AppBar
    );
  }

  // Widget pour la section "Votre solde disponible"
  Widget _buildSoldeDisponible(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Votre solde disponible',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '78 500 FCFA',
                style: GoogleFonts.lato( // Exemple d'utilisation de Google Fonts
                  fontSize: 22.0,
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Handle recharge action
            },
            child: Text('Recharger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la section "Résumé de votre commande"
  Widget _buildResumeCommande(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Résumé de votre commande',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.0),
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22.0,
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.location_on_outlined, color: Colors.blue[700]),
              ),
              SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Parcours "Après-midi Détente"', style: Theme.of(context).textTheme.bodyLarge),
                  Text('Terrasse du Café • 14h00', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  Text('Spa Relaxation • 16h30', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  Text('2 personnes', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Total à payer:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '58 300 FCFA',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour la section "Mode de paiement"
  Widget _buildModePaiement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Mode de paiement',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.0),
        Row(
          children: <Widget>[
            ElevatedButton(
              onPressed: () {},
              child: Text('Mon Compte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
            ),
            SizedBox(width: 8.0),
            OutlinedButton(
              onPressed: () {},
              child: Text('KiaKiaPay'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
            ),
            SizedBox(width: 8.0),
            OutlinedButton(
              onPressed: () {},
              child: Text('Mobile'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget pour la section "Paiement avec votre solde"
  Widget _buildPaiementSolde(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Paiement avec votre solde',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.0),
          _buildSoldeRow(context, 'Solde actuel:', '78 500 FCFA'),
          SizedBox(height: 8.0),
          _buildSoldeRow(context, 'Montant à débiter:', '- 58 300 FCFA', color: Colors.red[600]),
          SizedBox(height: 12.0),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 12.0),
          _buildSoldeRow(context, 'Nouveau solde:', '20 200 FCFA', weight: FontWeight.bold, color: Colors.green[600]),
        ],
      ),
    );
  }

  // Widget réutilisable pour les lignes de solde
  Widget _buildSoldeRow(BuildContext context, String label, String value, {FontWeight? weight, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: weight, color: color),
        ),
      ],
    );
  }

  // Widget pour les boutons de paiement
  Widget _buildPayButtons(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Payer avec mon compte', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
        SizedBox(height: 12.0),
        Center(child: Text('ou', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]))),
        SizedBox(height: 12.0),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: ()  {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KKiaPay(
                              amount: 1000,
                              sandbox: true,
                              apikey: 'ee3d2ea019fe11f094fdd7adc589b640',
                              callback: callback,
                              countries: ["BJ"],
                              phone: "22961000000",
                              name: "John Doe",
                              email: 'email@email.com',
                              reason: 'Paiement frais de visite',
                              data: 'Fake data',
                              theme: defaultTheme,
                              partnerId: 'AxXxXXxId',
                              paymentMethods: ["momo"]),
                        ),
                      );
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),

            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Utiliser KiaKiaPay', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour le footer de sécurité
  Widget _buildSecuriteFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Paiement sécurisé', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        SizedBox(width: 4.0),
        Icon(Icons.lock_outline, size: 16.0, color: Colors.grey[600]),
        SizedBox(width: 4.0),
        Text('Vos données sont protégées', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
      ],
    );
  }
}

void callback(response, context) {
  switch ( response['status'] ) {

    case PAYMENT_CANCELLED:
      Navigator.pop(context);
      debugPrint(PAYMENT_CANCELLED);
    break;

    case PAYMENT_INIT:
      debugPrint(PAYMENT_INIT);
      break;

    case PENDING_PAYMENT:
      debugPrint(PENDING_PAYMENT);
      break;
      
    case PAYMENT_SUCCESS:
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessScreen(
            amount: response['requestData']['amount'],
            transactionId: response['transactionId'],
          ),
        ),
      );
      break;

    default:
      debugPrint('');
      break;
  }
}