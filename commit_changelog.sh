if ! git diff --quiet CHANGELOG.md; then
  git add CHANGELOG.md
  git commit -m "update CHANGELOG.md"
  git push
fi
