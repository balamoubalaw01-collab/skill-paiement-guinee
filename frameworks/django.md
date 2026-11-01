# Django

Légende : ✅ testé · 🟡 API standard du framework, non exécutée ici.

## Configuration

🟡 Clés lues depuis l'environnement dans `settings.py` (`os.environ[...]`, ou `django-environ` si le projet l'utilise déjà). Jamais de clé en dur ni dans un fichier versionné.

## Webhook

✅ Vue testée (Django 6.1, client de test avec CSRF actif, signature générée par le SDK officiel FedaPay) :
```python
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from django.conf import settings
from .fedapay_signature import verifier_signature_fedapay   # copie de outils/fedapay_signature.py

@csrf_exempt              # le webhook vient de l'agrégateur, pas d'un formulaire
@require_POST
def webhook_fedapay(request):
    corps_brut = request.body                               # bytes, AVANT json.loads
    entete = request.headers.get("X-Fedapay-Signature", "")
    if not verifier_signature_fedapay(corps_brut, entete, settings.FEDAPAY_WEBHOOK_SECRET):
        return JsonResponse({"ok": False}, status=401)
    # enregistrer l'événement (doublon -> 200), getPaymentStatus, appliquer_transition...
    return JsonResponse({"ok": True})
```
Comparaison de secret (KkiaPay) : `hmac.compare_digest(attendu, request.headers.get("X-Kkiapay-Secret", ""))`.
Django REST Framework : une `APIView` avec `authentication_classes = []`, `permission_classes = [AllowAny]`, et lecture de `request.body` avant tout accès à `request.data`.

## Base de données

✅ Mise à jour filtrée (testée avec Django 6.1 : renvoie 1, puis 0 au second passage) :
```python
from django.db import transaction, IntegrityError

with transaction.atomic():
    n = Payment.objects.filter(pk=pid, status__in=depuis).update(status=vers)
    if n == 1:
        Order.objects.filter(pk=order_id, status="awaiting_payment").update(status="paid")
        transaction.on_commit(lambda: livrer_commande.delay(order_id))   # Celery, ou la file du projet
```
Alternative : `Payment.objects.select_for_update().get(pk=pid)` dans `transaction.atomic()`.
🟡 Contraintes dans `Meta.constraints` :
```python
models.UniqueConstraint(fields=["provider", "provider_ref"], name="paiement_ref_unique"),
models.UniqueConstraint(fields=["order"], condition=Q(status="succeeded", anomalie__isnull=True), name="un_succes_par_commande"),
```
Les contraintes **conditionnelles** sont gérées par PostgreSQL et SQLite, **pas par MySQL** (Django les ignore) : sur MySQL, utilise la colonne `success_order_id` unique (voir `fiabilite-paiements.md`). Erreur d'unicité : `IntegrityError`.

## Tâches de fond

🟡 Réutilise Celery / RQ / Django-Q si présent (Celery beat pour la planification). Sinon : une commande de gestion (`python manage.py rattraper_paiements`) lancée par cron toutes les 5 minutes, et une autre pour la réconciliation quotidienne.

## Tests

🟡 `responses` (requests) ou `respx` (httpx) pour simuler l'agrégateur ; `Client().post(url, data=corps, content_type="application/json", HTTP_X_FEDAPAY_SIGNATURE=entete)` pour le webhook ; `TransactionTestCase` + PostgreSQL pour la concurrence (les `TestCase` classiques enveloppent tout dans une transaction et masquent les problèmes de verrou).
