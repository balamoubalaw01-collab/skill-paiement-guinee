# Flutter (appli mobile)

Légende : ✅ testé · 🟡 API standard, non exécutée ici.

L'appli mobile **ne parle jamais directement à l'API de l'agrégateur avec une clé secrète**. Elle parle à **ton serveur** (Express, Next.js, Laravel, Django… voir les autres guides), qui parle à l'agrégateur.

## Ce qui est interdit dans l'appli

- clé secrète, clé privée, secret de webhook ;
- même « cachés » : un fichier `.env` chargé par `flutter_dotenv` est **inclus dans l'appli** ; une valeur passée avec `--dart-define` est **lisible** dans le binaire ; l'obfuscation ne protège pas un secret ;
- décider qu'une commande est payée.

Autorisé : l'URL de ton serveur, et une clé **publique** si le SDK de l'agrégateur l'exige (widget KkiaPay, SDK FeexPay Flutter…).

## Parcours

🟡 Création :
```dart
final res = await api.post('/payments', body: {
  'order_id': orderId,
  'network': reseau,            // si paiement direct
  'phone': numero,              // si paiement direct
}, headers: {'Idempotency-Key': cleTentative});   // une clé (UUID) par tentative, gardée si on réessaie la même tentative
```
- La réponse contient une **URL de paiement** → l'ouvrir avec `url_launcher` (navigateur externe) ou une WebView ; au retour (deep link ou retour dans l'appli), **interroger le serveur**.
- Ou bien « demande envoyée » → écran « Confirme le paiement sur ton téléphone avec ton code PIN ».

🟡 Attente du résultat (interroger **ton** serveur) :
```dart
Timer? _minuteur;
void suivre(String paymentId) {
  final fin = DateTime.now().add(const Duration(minutes: 3));
  _minuteur = Timer.periodic(const Duration(seconds: 4), (t) async {
    final p = await api.get('/payments/$paymentId');
    if (p['status'] == 'succeeded' || p['status'] == 'failed' || p['status'] == 'cancelled' || p['status'] == 'expired') {
      t.cancel(); afficherResultat(p['status']);
    } else if (DateTime.now().isAfter(fin)) {
      t.cancel(); afficherDelaiDepasse();   // « Si tu as été débité, ton paiement sera confirmé automatiquement. »
    }
  });
}
@override
void dispose() { _minuteur?.cancel(); super.dispose(); }
```
- Quand l'appli revient au premier plan (`AppLifecycleState.resumed`), revérifie le statut une fois.
- Bouton « Payer » désactivé pendant la requête (double clic).

## SDK d'agrégateur dans Flutter

Si l'agrégateur fournit un widget Flutter (KkiaPay, `feexpay_flutter_v2`…), son callback de succès sert **seulement** à prévenir ton serveur (envoyer la référence). Le serveur vérifie avec `getPaymentStatus` avant toute livraison. La doc du SDK FeexPay v2 le dit elle-même : le résultat reçu dans l'appli peut être falsifié.

## États à afficher

En attente · Réussi · Échoué (avec « Réessayer », qui crée une **nouvelle** tentative) · Délai dépassé · Erreur réseau (« Vérifie ta connexion », sans conclure sur le paiement).

## Tests

🟡 `MockClient` (`package:http/testing.dart`) pour simuler ton serveur : réponses `processing` puis `succeeded`, erreur réseau, délai dépassé, réponse inattendue.
