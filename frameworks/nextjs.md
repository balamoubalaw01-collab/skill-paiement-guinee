# Next.js

Légende : ✅ testé · 🟡 API standard du framework, non exécutée ici.

## Où mettre le code

- Le code de paiement (adaptateurs, clés) ne vit **que** côté serveur : Route Handlers (`app/api/.../route.ts`), Server Actions ou routes API (`pages/api`). Marque les modules sensibles avec `import 'server-only'` pour qu'un import accidentel côté client échoue au build.
- 🟡 Variables d'environnement : les clés secrètes **sans** préfixe `NEXT_PUBLIC_`. Tout ce qui commence par `NEXT_PUBLIC_` est envoyé au navigateur : seule une clé **publique** (widget KkiaPay, par exemple) peut l'avoir.
- Création du paiement : Route Handler ou Server Action appelée par le client, avec l'utilisateur authentifié.
- **Webhook : toujours un Route Handler**, jamais une Server Action (une Server Action n'est pas une URL stable appelable par un service externe).

## Webhook : corps brut

🟡 App Router :
```ts
// app/api/webhooks/fedapay/route.ts
export const runtime = 'nodejs';        // crypto Node et SDK officiels ; pas le runtime edge
export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  const corpsBrut = await req.text();   // AVANT tout req.json()
  const v = await adaptateurs.fedapay.verifyWebhook(corpsBrut, Object.fromEntries(req.headers));
  if (!v.valide) return new Response('signature invalide', { status: 401 });
  // enregistrer l'événement, getPaymentStatus, appliquerTransition…
  return Response.json({ ok: true });
}
```
🟡 Pages Router : désactive le parseur (`export const config = { api: { bodyParser: false } }`) et lis le flux toi-même (paquet `raw-body` ou lecture des chunks).

Vérifie que le **middleware** d'authentification (`middleware.ts`) laisse passer `/api/webhooks/*`.

## Hébergement serverless (Vercel, Netlify…)

- Pas de tâche qui tourne en continu : le rattrapage et la réconciliation sont des routes protégées (secret dans un en-tête, par exemple `Authorization: Bearer ${CRON_SECRET}`) appelées par le cron de la plateforme (Vercel Cron Jobs) ou un cron externe.
- Durée maximale d'une fonction : un appel d'agrégateur qui attend la validation du client (FeexPay, par exemple) peut dépasser la limite. Mets un délai côté client plus court que la limite, traite le dépassement comme « en cours », et laisse le rattrapage conclure.
- Pas d'effet après réponse garanti sans outil dédié : traite le webhook **avant** de répondre (rapidement), ou utilise une file (Inngest, QStash, etc.) si le projet en a une.

## Base de données

🟡 Prisma / Drizzle : mêmes règles que `express.md` (mise à jour filtrée qui renvoie le nombre de lignes, transaction courte, unicité). En serverless, utilise le pooler de connexions prévu par l'hébergeur de la base.

## Interface

Composant client qui appelle la route de création, puis interroge `GET /api/payments/[id]` toutes les 3 à 5 s (arrêt au démontage et après le délai). La page de retour (`callback_url`) affiche le statut **de ta base**, jamais celui de l'URL.
