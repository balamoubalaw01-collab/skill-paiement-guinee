# Express / Node.js

Légende : ✅ testé · 🟡 API standard du framework, non exécutée ici.

## Webhook : corps brut

✅ (testé avec express + SDK fedapay 1.2.5) La route du webhook lit le corps **brut**. Déclare-la **avant** `app.use(express.json())`, ou donne-lui son propre parseur :
```js
app.post('/webhooks/fedapay', express.raw({ type: 'application/json' }), async (req, res) => {
  const v = await adaptateurs.fedapay.verifyWebhook(req.body, req.headers);   // req.body est un Buffer
  if (!v.valide) return res.status(401).end();
  const nouveau = await enregistrerEvenement('fedapay', v.eventKey);
  if (!nouveau) return res.status(200).json({ ok: true });                   // doublon
  res.status(200).json({ ok: true });                                         // répondre vite…
  traiterEnArrierePlan('fedapay', v.referenceFournisseur);                    // …puis getPaymentStatus + appliquerTransition
});
app.use(express.json()); // pour le reste de l'API
```
Si le projet doit répondre seulement après traitement, traite d'abord puis réponds, mais reste sous quelques secondes.

Comparaison de secret à temps constant (KkiaPay) :
```js
const crypto = require('crypto');
function egal(a, b) {
  const x = Buffer.from(String(a || '')), y = Buffer.from(String(b || ''));
  return x.length === y.length && crypto.timingSafeEqual(x, y);   // timingSafeEqual lève une erreur si les longueurs diffèrent
}
```

## Base de données

🟡 Mise à jour atomique selon l'outil du projet :
- `pg` / Knex : `UPDATE ... WHERE id = $1 AND status = ANY($2)` puis `rowCount` (✅ testé avec `pg` dans `outils/test-concurrence-postgres.js`).
- Prisma : `const r = await tx.payment.updateMany({ where: { id, status: { in: depuis } }, data: { status: vers } }); if (r.count === 1) {...}` dans `prisma.$transaction(async (tx) => {...})`. Unicité : `@@unique([provider, providerRef])` ; index partiel : migration SQL manuelle. Erreur d'unicité : code `P2002`.
- Sequelize / TypeORM : `update(..., { where })` renvoie le nombre de lignes ; idem.

## Tâches de fond

🟡 Réutilise ce qui existe (BullMQ, Agenda, worker maison). Sinon :
- un seul processus : `node-cron` pour le rattrapage et la réconciliation ;
- plusieurs instances (PM2 en cluster, plusieurs conteneurs) : un seul planificateur, ou un verrou (`pg_try_advisory_lock`, verrou Redis) pour éviter les exécutions doubles.
- effets après commit : table outbox lue par le worker.

## Configuration

`process.env` + `.env` (dotenv) côté serveur seulement. Valide au démarrage que toutes les variables de paiement existent (le projet a peut-être déjà un validateur d'env : réutilise-le).

## Tests

✅ `nock` pour simuler l'agrégateur (ajoute les hôtes simulés à `NO_PROXY` derrière un proxy) ; `supertest` ou `http` natif pour appeler la route du webhook ; vraie base pour les tests de concurrence.
