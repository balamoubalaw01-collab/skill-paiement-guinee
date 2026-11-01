# Laravel

Légende : ✅ testé · 🟡 API standard du framework, non exécutée ici.

## Configuration

🟡 Les clés vont dans `.env`, lues **uniquement** dans `config/services.php` :
```php
'fedapay' => [
    'secret' => env('FEDAPAY_SECRET_KEY'),
    'webhook_secret' => env('FEDAPAY_WEBHOOK_SECRET'),
    'env' => env('FEDAPAY_ENV', 'sandbox'),
],
```
Dans le code : `config('services.fedapay.secret')`, jamais `env()` (qui renvoie `null` après `php artisan config:cache`).

## Webhook

🟡 Route dans `routes/api.php` (pas de protection CSRF sur les routes API). Si elle doit être dans `routes/web.php`, exclus-la du CSRF :
- Laravel 11 et + : `bootstrap/app.php` → `->withMiddleware(function (Middleware $middleware) { $middleware->validateCsrfTokens(except: ['webhooks/*']); })`
- Laravel 10 et - : tableau `$except` de `app/Http/Middleware/VerifyCsrfToken.php`.
(Laravel 11 : les routes API demandent `php artisan install:api` si `routes/api.php` n'existe pas.)

✅ Vérification FedaPay (SDK `fedapay/fedapay-php` 0.4.9, testée) :
```php
public function __invoke(Request $request)
{
    try {
        $event = \FedaPay\Webhook::constructEvent(
            $request->getContent(),                       // corps BRUT
            $request->header('X-FEDAPAY-SIGNATURE'),
            config('services.fedapay.webhook_secret')
        );
    } catch (\FedaPay\Error\SignatureVerification $e) {
        return response()->json(['ok' => false], 401);
    }
    // enregistrer l'événement (doublon -> 200), getPaymentStatus, appliquerTransition...
    return response()->json(['ok' => true]);
}
```
Comparaison de secret (KkiaPay) : `hash_equals($attendu, (string) $request->header('x-kkiapay-secret'))`.

## Base de données

🟡 Transition atomique :
```php
DB::transaction(function () use ($payment, $vers, $depuis) {
    $n = Payment::whereKey($payment->id)->whereIn('status', $depuis)->update(['status' => $vers]);
    if ($n === 1) {
        Order::whereKey($payment->order_id)->where('status', 'awaiting_payment')->update(['status' => 'paid']);
        DB::afterCommit(fn () => LivrerCommande::dispatch($payment->order_id));
    }
});
```
Alternative : `Payment::whereKey($id)->lockForUpdate()->first()` dans la transaction.
Unicité dans la migration : `$table->unique(['provider', 'provider_ref']);`. Index partiel (PostgreSQL) : `DB::statement("CREATE UNIQUE INDEX ... WHERE status = 'succeeded' AND anomalie IS NULL")`. Erreur d'unicité : `Illuminate\Database\UniqueConstraintViolationException` (Laravel 10.21+), sinon `QueryException`.

## Tâches de fond

🟡 Jobs dans la file existante (`ShouldQueue`), lancés `->afterCommit()`.
Planification :
- Laravel 11 et + : `routes/console.php` → `Schedule::job(new RattraperPaiements)->everyFiveMinutes()->withoutOverlapping();`
- Laravel 10 et - : `app/Console/Kernel.php`, méthode `schedule()`.
Et la ligne cron du serveur : `* * * * * php /chemin/artisan schedule:run`. Plusieurs serveurs : `->onOneServer()` (cache partagé requis).

## SDK

✅ FedaPay : `fedapay/fedapay-php` (webhook testé). ✅ FeexPay : `feexpay/feexpay-php` 3.x (signatures des méthodes lues ; voir `feexpay.md`). KkiaPay : SDK Admin PHP de la doc, ou appel HTTP avec `Http::withHeaders([...])->post(...)` (voir `kkiapay.md`).

## Tests

🟡 `Http::fake([...])` pour simuler l'agrégateur, `Http::preventStrayRequests()` pour interdire tout appel réel, `$this->postJson()` / `$this->call()` avec un corps brut pour le webhook, base PostgreSQL / MySQL de test pour la concurrence.
