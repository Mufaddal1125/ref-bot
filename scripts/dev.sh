#!/usr/bin/env bash
# Start infrastructure and migrate. Run the backend, worker, and client in your own terminals.
#
#   scripts/dev.sh

set -euo pipefail
cd "$(dirname "$0")/.."

py="backend/.venv/bin/python"
if [ ! -x "$py" ]; then
  echo "No virtualenv. Run the setup steps in README.md first."
  exit 1
fi

docker compose up -d
"$py" backend/manage.py migrate

cat <<'EOF'

Infrastructure is up. In three terminals:

  backend/.venv/bin/python backend/manage.py runserver
  backend/.venv/bin/python backend/manage.py rqworker referee
  cd app && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
EOF
