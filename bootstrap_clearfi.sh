#!/usr/bin/env bash
set -euo pipefail

# ===== settings =====
REPO_NAME="clearfi"
APPS=("web" "app" "admin")

echo ">>> Bootstrapping monorepo '$REPO_NAME' ..."

# ----- basic checks -----
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js ontbreekt. In Codespaces staat het er meestal al op. Stop."
  exit 1
fi

# enable corepack for pnpm
if ! command -v pnpm >/dev/null 2>&1; then
  echo ">>> Activating corepack for pnpm"
  corepack enable || true
fi
corepack prepare pnpm@latest --activate

# ----- init workspace -----
echo ">>> Initializing package.json (workspace root)"
jq -n \
  --arg name "$REPO_NAME" \
  '{
     name: $name,
     private: true,
     packageManager: "pnpm@9.0.0",
     scripts: {
       "build": "turbo build",
       "dev": "turbo dev",
       "lint": "turbo lint",
       "format": "prettier --write ."
     },
     devDependencies: {
       "turbo": "^2.0.0",
       "prettier": "^3.3.3"
     },
     workspaces: [
       "apps/*",
       "packages/*"
     ]
   }' > package.json

mkdir -p apps packages

# ----- prettier config -----
cat > .prettierrc.json <<'JSON'
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100
}
JSON

# ----- turbo config -----
cat > turbo.json <<'JSON'
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "build/**"]
    },
    "dev": {
      "cache": false
    },
    "lint": {
      "outputs": []
    }
  }
}
JSON

# ----- shared tsconfig -----
mkdir -p packages/config
cat > packages/config/tsconfig.base.json <<'JSON'
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "strict": true,
    "noEmit": true,
    "jsx": "preserve",
    "incremental": true,
    "types": ["node"]
  }
}
JSON

# ----- shared eslint config -----
mkdir -p packages/config/eslint
cat > packages/config/eslint/.eslintrc.js <<'JS'
/** @type {import('eslint').Linter.Config} */
module.exports = {
  root: false,
  extends: ['next/core-web-vitals', 'eslint:recommended'],
  parserOptions: { ecmaVersion: 2022, sourceType: 'module' },
  rules: {
    'no-console': ['warn', { allow: ['warn', 'error'] }]
  }
};
JS

# ----- create next.js apps -----
for app in "${APPS[@]}"; do
  echo ">>> Creating Next.js app: $app"
  pnpm dlx create-next-app@latest "apps/$app" \
    --typescript \
    --eslint \
    --tailwind \
    --app \
    --src-dir=false \
    --import-alias="@/*" \
    --use-pnpm \
    --no-git \
    --turbo
  # align tsconfig to shared base
  jq '.extends = "../../packages/config/tsconfig.base.json"' "apps/$app/tsconfig.json" > "apps/$app/tsconfig.tmp.json"
  mv "apps/$app/tsconfig.tmp.json" "apps/$app/tsconfig.json"

  # align eslint to shared
  cat > "apps/$app/.eslintrc.js" <<'JS'
/** @type {import('eslint').Linter.Config} */
module.exports = {
  root: true,
  extends: ['../../packages/config/eslint/.eslintrc.js']
};
JS

  # simple health page with app name
  mkdir -p "apps/$app/app"
  cat > "apps/$app/app/page.tsx" <<TSX
export default function Page() {
  return (
    <main className="p-10">
      <h1 className="text-2xl font-semibold">Hello from ${app}</h1>
      <p>Dit is de ${app}-app van Clearfi.</p>
    </main>
  );
}
TSX
done

# ----- root README -----
cat > README.md <<'MD'
# clearfi monorepo

- `apps/web` → marketing site (clearfi.nl)
- `apps/app` → klantomgeving (app.clearfi.nl)
- `apps/admin` → admin logs (admin.clearfi.nl)

## Scripts
- `pnpm dev` – start alle apps (turbo)
- `pnpm build` – build alle apps
- `pnpm lint` – lint alle apps
- `pnpm format` – prettier over de repo

## Ontwikkelen
In 2 terminals:
1) `pnpm dev` (root)
2) open de app-URL die Next toont (poortjes 3000/3001/3002)

## Volgende stappen
- Auth (email+password) met Auth.js
- Database (Postgres) met Prisma
- Domeinen & deploy
MD

# ----- install root deps (turbo/prettier) -----
pnpm install

echo ">>> DONE"
echo "---------------------------------------"
echo "Monorepo klaar."
echo "- Apps: apps/web, apps/app, apps/admin"
echo "- Run: pnpm dev"
echo "---------------------------------------"
