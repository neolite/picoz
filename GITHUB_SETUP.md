# GitHub Setup Instructions

## Шаги для публикации PicoZ на GitHub

### 1. Создайте новый репозиторий на GitHub

1. Зайдите на https://github.com/new
2. Название: `picoz`
3. Description: `Complete Zig port of PicoClaw - Ultra-lightweight AI assistant (10x smaller binary)`
4. Public репозиторий
5. **НЕ** добавляйте README, .gitignore, license (уже есть)

### 2. Подключите удаленный репозиторий

```bash
cd /Users/rafkat/Apps/rafkat/picoz-repo

# Добавьте remote (замените YOUR_USERNAME на ваш GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/picoz.git

# Проверьте
git remote -v
```

### 3. Запушьте код

```bash
# Push main branch
git push -u origin master

# Или если используете main
git branch -M main
git push -u origin main
```

### 4. Создайте релиз на GitHub

#### Через веб-интерфейс:

1. Перейдите на https://github.com/YOUR_USERNAME/picoz/releases
2. Нажмите "Create a new release"
3. Tag version: `v0.1.0`
4. Release title: `v0.1.0 - Initial Release`
5. Description: Скопируйте из `releases/RELEASE_NOTES.md`
6. Прикрепите файлы:
   - `releases/picoz-macos-arm64`
   - `releases/picoz-linux-x86_64`
   - `releases/picoz-linux-arm64`
   - `releases/picoz-linux-riscv64`
7. Нажмите "Publish release"

#### Через GitHub CLI (если установлен):

```bash
# Создайте тег
git tag -a v0.1.0 -m "Initial release - Complete PicoClaw port"
git push origin v0.1.0

# Создайте релиз
gh release create v0.1.0 \
  releases/picoz-* \
  --title "v0.1.0 - Initial Release" \
  --notes-file releases/RELEASE_NOTES.md
```

### 5. Обновите README

В README.md замените `YOUR_USERNAME` на ваш GitHub username:

```bash
# Найдите и замените (macOS/Linux)
sed -i '' 's/YOUR_USERNAME/your-actual-username/g' README.md
sed -i '' 's/YOUR_USERNAME/your-actual-username/g' releases/RELEASE_NOTES.md

# Commit изменения
git add README.md releases/RELEASE_NOTES.md
git commit -m "docs: update GitHub username in links"
git push
```

### 6. Настройте Topics на GitHub

Перейдите в Settings → (scroll to Topics) → добавьте:
- `zig`
- `ai-assistant`
- `picoclaw-port`
- `llm`
- `minimal-binary`
- `embedded`
- `riscv`

### 7. Опционально: GitHub Actions для автоматической сборки

Создайте `.github/workflows/build.yml` для автоматической сборки релизов.

## Готово! 🎉

Ваш репозиторий теперь доступен по адресу:
https://github.com/YOUR_USERNAME/picoz

Релизы доступны:
https://github.com/YOUR_USERNAME/picoz/releases

## Размеры бинарников

```
picoz-linux-riscv64   25K  (400x меньше чем Go!)
picoz-linux-arm64     32K  (312x меньше)
picoz-linux-x86_64    33K  (300x меньше)
picoz-macos-arm64     78K  (128x меньше)
```

**Невероятно маленькие бинарники благодаря Zig ReleaseSmall!**

---

皮皮虾，我们走！🦐
