# Dossier `dist/` — paquets prêts à distribuer

Généré depuis le pack `skill-paiement-guinee`. Ne pas éditer à la main : régénérer après
toute modification du pack.

| Fichier | Taille | Usage |
|---|---|---|
| `PAIEMENT-GUINEE-PACK.md` | 138 Ko | Document unique contenant **tous** les fichiers du skill, dans l'ordre de lecture. À déposer comme fichier de connaissances dans un Projet ChatGPT. |
| `INSTRUCTIONS-CHATGPT.md` | 5,7 Ko | Version condensée (sous la limite de 8 000 caractères) à coller dans le champ **Instructions** d'un GPT personnalisé ou d'un Projet. |
| `skill-paiement-guinee.zip` | 71 Ko | Archive complète du skill, sans `.git`. Pour import dans Claude, VS Code, Cursor, ou toute IA qui lit des fichiers. |
| `skill-paiement-guinee.bundle` | 70 Ko | Miroir Git complet (historique inclus). Sert à republier le dépôt sur un autre compte GitHub sans perdre les commits. Fichier **généré localement**, volontairement exclu du dépôt (il se contiendrait lui-même). |

Régénérer le miroir après chaque commit :

```powershell
git bundle create dist/skill-paiement-guinee.bundle --all
```

## 1. Installer dans ChatGPT

**Option A — Projet ChatGPT (recommandé, garde tout le contenu)**

1. ChatGPT → **Projets** → *Nouveau projet* → nommer `Paiement Guinée`.
2. **Instructions du projet** : coller le contenu de `INSTRUCTIONS-CHATGPT.md`.
3. **Fichiers** : ajouter `PAIEMENT-GUINEE-PACK.md`.
4. Dans le projet, écrire : `Utilise le pack paiement Guinée pour intégrer Orange Money dans mon appli de gestion des élèves, montants en GNF.`

**Option B — GPT personnalisé**

1. ChatGPT → **Explorer les GPT** → *Créer* → onglet **Configurer**.
2. **Instructions** : coller `INSTRUCTIONS-CHATGPT.md` (reste sous les 8 000 caractères).
3. **Connaissances** : téléverser `PAIEMENT-GUINEE-PACK.md`.
4. Capacités : *Code Interpreter* utile, *Navigation* non nécessaire.

**Option C — sans téléversement**

Coller `INSTRUCTIONS-CHATGPT.md` dans une conversation et joindre le `.md` du pack à la
question. Fonctionne aussi avec Claude, Gemini, Mistral, Copilot.

> Un `.zip` n'est pas lu de façon fiable par ChatGPT comme base de connaissances.
> Utiliser le `.md` consolidé, pas l'archive.

## 2. Republier sur un autre compte GitHub

Le transfert direct entre deux comptes ne peut pas être fait par un agent : GitHub exige
que le compte cible accepte. Deux chemins.

### Chemin 1 — depuis le compte cible (le plus simple)

Se connecter avec **le compte cible**, puis :

1. Créer un dépôt vide nommé `skill-paiement-guinee` (sans README, sans .gitignore).
2. Sur la machine, avec les identifiants du compte cible :

```powershell
git clone https://github.com/balamoubalaw01-collab/skill-paiement-guinee.git
cd skill-paiement-guinee
git remote set-url origin https://github.com/NOUVEAU-COMPTE/skill-paiement-guinee.git
git push -u origin main
```

### Chemin 2 — via le miroir, sans accès réseau au dépôt d'origine

```powershell
git clone skill-paiement-guinee.bundle skill-paiement-guinee
cd skill-paiement-guinee
git remote set-url origin https://github.com/NOUVEAU-COMPTE/skill-paiement-guinee.git
git push -u origin main
```

### Chemin 3 — transfert officiel avec conservation des étoiles et des liens

Depuis le compte **propriétaire actuel** (`balamoubalaw01-collab`) :
`Settings` → onglet `General` → bas de page `Danger Zone` → **Transfer ownership** →
saisir le nom du compte cible → confirmer. Le compte cible reçoit un courriel et doit
accepter. Les redirections d'URL sont conservées.

## 3. Vérifier après transfert

```powershell
git ls-remote https://github.com/NOUVEAU-COMPTE/skill-paiement-guinee.git
```

Doit renvoyer une ligne `refs/heads/main` avec le SHA `44fc8ed`.

## Régénérer ce dossier

```powershell
# depuis la racine du pack
# reconstruire PAIEMENT-GUINEE-PACK.md, le zip et le bundle avec le même script
```
