# mbp2019-slowdown

Исследование тормозов MacBook Pro 16" 2019 (i7, Radeon Pro 5300M + Intel UHD 630, 16 ГБ).

- `RESEARCH.md` — причины, варианты «атаки», рейтинги, наш статус проверки
- `collect-facts.sh` — сбор фактов с машины (только чтение)

## Запуск на Mac

```bash
git clone https://github.com/antlbn/mbp2019-slowdown.git
cd mbp2019-slowdown
sudo bash collect-facts.sh
```

Отчёты складываются в `reports/` (имя пользователя в путях маскируется). Перед пушем пролистайте отчёт: репозиторий публичный, список программ виден всем.
