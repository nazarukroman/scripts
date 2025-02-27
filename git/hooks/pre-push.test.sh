#!/bin/bash

# ====== Определяем корень репозитория ======
REPO_ROOT=$(git rev-parse --show-toplevel)
PRE_PUSH_SCRIPT="$REPO_ROOT/.husky/pre-push"

# ====== Цветовые коды ======
RESET="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"

# ====== Функция логирования ======
log_success() {
  echo -e "${GREEN}[TEST SUCCESS]${RESET} $1"
}

log_failure() {
  echo -e "${RED}[TEST FAILED]${RESET} $1"
}

# ====== Запуск тестов ======
echo "🔍 Запуск тестов для pre-push..."

# ====== Тест 1: Скрипт должен выполняться без ошибок ======
if [ ! -f "$PRE_PUSH_SCRIPT" ]; then
  log_failure "Тест 1: Файл pre-push не найден в .husky/"
  exit 1
fi

chmod +x "$PRE_PUSH_SCRIPT"  # Убеждаемся, что файл исполняемый
"$PRE_PUSH_SCRIPT" > output.log 2>&1
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  log_success "Тест 1: Скрипт выполняется без ошибок"
else
  log_failure "Тест 1: Ошибка выполнения скрипта (код $EXIT_CODE)"
  exit 1
fi

# ====== Тест 2: Проверяем обработку отсутствия изменений ======
git diff --name-only origin/master..HEAD > /dev/null 2>&1
if [ ! -eq 0 ]; then
  grep -q "✅ Нет изменений в файлах" output.log
  if [ ! -eq 0 ]; then
    log_success "Тест 2: Корректная обработка отсутствия изменений"
  else
    log_failure "Тест 2: Ошибка обработки отсутствия изменений"
    exit 1
  fi
else
  log_success "Тест 2: Пропущен (есть изменения в Git)"
fi

# ====== Тест 3: Проверяем обработку отсутствия package.json ======
mv "$REPO_ROOT/package.json" "$REPO_ROOT/package.json.bak"
"$PRE_PUSH_SCRIPT" > output.log 2>&1
grep -q "Файл package.json не найден!" output.log
if [ $? -ne 1 ]; then
  log_success "Тест 3: Корректная обработка отсутствия package.json"
else
  log_failure "Тест 3: Ошибка обработки отсутствия package.json"
  mv "$REPO_ROOT/package.json.bak" "$REPO_ROOT/package.json"
  exit 1
fi
mv "$REPO_ROOT/package.json.bak" "$REPO_ROOT/package.json"

# ====== Тест 4: Проверяем запуск pre-push в workspace ======
mkdir "$REPO_ROOT/apps/a"
touch "$REPO_ROOT/apps/a/file1.js"
git add "$REPO_ROOT/apps/a/file1.js"
git commit -m 'Test pre-push' --no-verify
"$PRE_PUSH_SCRIPT" > output.log 2>&1
grep -q "🚀 Запускаем pre-push для" output.log
if [ $? -ne 1 ]; then
  log_success "Тест 4: pre-push успешно запускается для workspaces"
else
  log_failure "Тест 4: Ошибка запуска pre-push в workspaces"

  git reset HEAD~1
  rm -rf "$REPO_ROOT/apps/a"

  exit 1
fi
git reset HEAD~1
rm -rf "$REPO_ROOT/apps/a"

# ====== Итог ======
echo "🎉 Все тесты выполнены успешно!"
exit 0
