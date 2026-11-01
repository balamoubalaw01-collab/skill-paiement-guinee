# S'adapter au projet existant

Le but est d'ajouter le paiement **dans** le projet, pas de reconstruire le projet autour du paiement. Moins de code, mais du code au bon endroit.

## 1. Détecter avant d'écrire

| À détecter | Où regarder |
| --- | --- |
| Langage et version | `package.json`, `composer.json`, `pyproject.toml` / `requirements.txt`, `pubspec.yaml`, `go.mod` |
| Framework | dépendances + structure (`app/` Next.js, `routes/` Laravel, `manage.py` Django, `lib/` Flutter…) |
| Base de données et ORM | Prisma, Drizzle, TypeORM, Sequelize, Eloquent, Django ORM, SQLAlchemy ; moteur réel (PostgreSQL, MySQL, SQLite) dans la config |
| Migrations | outil existant (Prisma Migrate, migrations Laravel / Django, Knex…) |
| Hébergement | `vercel.json`, `netlify.toml`, `Dockerfile`, `ecosystem.config.js` (PM2), `Procfile`, configuration Nginx, CI |
| Tâches de fond | file existante (BullMQ, Laravel Queue, Celery, RQ), cron, planificateur |
| Authentification | middleware / guard / décorateur existant pour protéger les routes |
| Conventions | nommage, dossiers, style des contrôleurs et services, gestion des erreurs, client HTTP utilisé, tests existants |
| Paiement existant | ancien code d'agrégateur, tables `payments` / `transactions`, webhooks déjà déclarés |

Résume ce que tu as trouvé à l'utilisateur en quelques lignes avant de coder.

## 2. Règles d'adaptation

- **Réutilise** : le client HTTP, l'ORM, le système de migrations, la file d'attente, le logger, le système d'alerte, les composants d'interface déjà présents.
- **Respecte** la structure : si les services sont dans `src/services/`, l'adaptateur y va aussi ; si le projet n'utilise pas de classes, n'en introduis pas.
- **Étends** l'existant : une table `payments` existe déjà → migration qui ajoute les colonnes manquantes, pas une deuxième table.
- **N'ajoute pas** de dépendance si le projet a déjà l'équivalent. Une nouvelle dépendance doit être justifiée (SDK officiel de l'agrégateur, par exemple).
- **Pas de refonte** non demandée (changement d'ORM, de framework, de structure de dossiers, de style). Si l'existant est dangereux (clé secrète dans l'appli, validation du paiement côté client), corrige **ce point** et explique pourquoi.
- **Hébergement** :
  - serverless (Vercel, Netlify, Lambda) : pas de tâche en arrière-plan qui tourne en continu → cron de la plateforme ou cron externe appelant une route protégée ; attention aux appels longs (certains agrégateurs attendent la validation du client) ;
  - serveur classique (VPS, PM2, Docker) : cron système, worker de file, ou planificateur du framework ;
  - plusieurs instances : le rattrapage et la réconciliation ne tournent qu'une fois à la fois (verrou).
- **Changement minimal mesurable** : à la fin, liste les fichiers créés et modifiés. Si la liste est longue, vérifie que chaque fichier est nécessaire.

## 3. Projet en production

Si l'appli est déjà utilisée par de vrais clients :
- migrations **additives** seulement (ajout de colonnes / tables, pas de suppression ni de renommage) ;
- l'ancien flux de paiement continue de marcher pendant la transition, ou la bascule est contrôlée par une variable de configuration ;
- travaille sur une branche, et propose une pull request plutôt qu'un changement direct sur la branche principale si le projet utilise Git ;
- ne déploie rien toi-même sans accord explicite.

## 4. Guides par framework

- Express / Node.js → `frameworks/express.md`
- Next.js → `frameworks/nextjs.md`
- Laravel → `frameworks/laravel.md`
- Django → `frameworks/django.md`
- Flutter (appli mobile) → `frameworks/flutter.md`

Autre framework (NestJS, FastAPI, Rails, Spring, Go…) : applique les mêmes principes en cherchant, dans la doc du framework, comment : lire le corps brut d'une requête, exclure une route de la protection CSRF, faire une transaction avec mise à jour filtrée, exécuter du code après le commit, planifier une tâche.
