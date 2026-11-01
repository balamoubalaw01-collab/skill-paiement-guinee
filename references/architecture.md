# Architecture commune : une interface, un adaptateur par agrégateur

But : changer d'agrégateur (ou en ajouter un deuxième) sans réécrire l'application. Le reste du code ne parle **qu'à l'interface**, jamais directement à FedaPay, KkiaPay ou FeexPay.

Avant de créer quoi que ce soit, lis `adaptation-projet.md` : si le projet a déjà un module de paiement, adapte-le au lieu d'en écrire un second.

## L'interface (à traduire dans le langage du projet)

```ts
type Operation = 'payin' | 'refund' | 'payout' | 'card' | 'recurring';
type Statut = 'pending' | 'processing' | 'succeeded' | 'failed' | 'cancelled' | 'expired' | 'refunded';

interface Capacites {
  operations: Operation[];            // seulement ce que l'agrégateur prend en charge ET qui est confirmé
  pays: string[];                      // ex. ['BJ', 'TG']
  reseaux: Record<string, string[]>;   // ex. { BJ: ['mtn', 'moov', 'celtiis'] }
  devises: string[];                   // ex. ['XOF']
  parcours: ('page' | 'widget' | 'direct')[];
  remboursementPartiel: boolean | 'inconnu';
}

interface ResultatStatut {
  statut: Statut | 'inconnu';          // déjà traduit par l'adaptateur
  statutFournisseur: string;           // valeur brute, pour le journal
  montant: number | null;              // entier, unité de la devise (le FCFA n'a pas de centimes)
  devise: string | null;
  frais: number | null;
  referenceFournisseur: string;
}

interface AdaptateurPaiement {
  readonly nom: string;                // 'fedapay', 'kkiapay', 'feexpay'…
  capacites(): Capacites;
  createPayment(p: { paiementId: string; montant: number; devise: string; client: {...};
                     reseau?: string; telephone?: string; urlRetour?: string; cleIdempotence: string })
    : Promise<{ referenceFournisseur: string | null; urlPaiement?: string; statut: Statut }>;
  getPaymentStatus(referenceFournisseur: string): Promise<ResultatStatut>;
  verifyWebhook(corpsBrut: Buffer | string, entetes: Record<string, string>)
    : Promise<{ valide: boolean; referenceFournisseur?: string; eventKey?: string }>;
  refundPayment?(referenceFournisseur: string, montant?: number): Promise<{ referenceRemboursement: string; statut: string }>;
  createPayout?(p: {...}): Promise<{...}>;
  getPayoutStatus?(reference: string): Promise<{...}>;
}
```

Règles :
- Une méthode facultative **n'existe pas** dans l'adaptateur si l'opération n'est pas prise en charge **ou** pas confirmée. Le code appelant vérifie `capacites()` et affiche « non disponible avec cet agrégateur », il n'improvise pas.
- `verifyWebhook` ne fait **que** l'authentification de la requête. La décision vient toujours de `getPaymentStatus`.
- La traduction des statuts du fournisseur vers les 7 statuts se fait **uniquement** dans l'adaptateur. Valeur inconnue → `'inconnu'`.
- Erreurs normalisées : `ErreurReseau`, `DelaiDepasse`, `RefusFournisseur` (avec le message réel), `ReponseInattendue`, `OperationNonPriseEnCharge`. `DelaiDepasse` et `ErreurReseau` ne signifient **jamais** « échec du paiement ».
- Chaque appel HTTP a un délai maximal explicite et journalise : méthode, URL sans secret, code HTTP, durée, référence. Jamais de clé, de PIN ni de numéro complet dans les logs.

## Organisation des fichiers (exemple, à adapter aux conventions du projet)

```
paiements/
  interface            (types, erreurs)
  registre             (choisit l'adaptateur selon la config : PAYMENT_PROVIDER=fedapay)
  adaptateurs/fedapay  adaptateurs/kkiapay  adaptateurs/feexpay
  service              (createPayment côté métier, appliquerTransition, rattrapage, réconciliation)
  webhooks             (une route par agrégateur, toutes appellent le service)
```

Plusieurs agrégateurs en même temps (par pays ou par réseau) : le registre choisit l'adaptateur par règle explicite (pays, réseau). Jamais de bascule automatique vers un autre agrégateur après une erreur : on risque un double débit.

## Opérations possibles

| Opération | À faire seulement si… | Points d'attention |
| --- | --- | --- |
| Pay-in mobile money | toujours (c'est le cœur) | parcours page / widget / direct |
| Paiement par carte | l'agrégateur le propose | souvent une page hébergée (3-D Secure) ; frais plus élevés ; jamais de numéro de carte sur ton serveur |
| Remboursement | API confirmée dans la doc | table `refunds` avec sa propre machine à états ; total remboursé ≤ montant payé |
| Payout (versement sortant) | API confirmée et compte autorisé | règles renforcées (`fiabilite-paiements.md` §4) ; solde ; validation humaine |
| Paiement récurrent | l'agrégateur a une vraie API d'abonnement ou de carte enregistrée | en mobile money, chaque débit demande en général un nouveau PIN : c'est une **nouvelle demande de paiement planifiée** que le client confirme, pas un prélèvement automatique |

Ce que chaque agrégateur propose (et le niveau de confiance) : voir sa fiche. Si une opération demandée n'est pas prise en charge, dis-le clairement à l'utilisateur et propose une alternative (autre agrégateur, opération manuelle depuis le tableau de bord).
