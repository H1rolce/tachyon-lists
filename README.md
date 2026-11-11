<div align="center">

# tachyon-lists

**Каталог списков доменов и подсетей [Tachyon Lists](https://github.com/Dushnilin/tachyon-lists) для zapret manager или splify2**

</div>

---

> [!IMPORTANT]
> **Автор исходных списков и компилятора:** [@Dushnilin](https://github.com/Dushnilin)  
> **Первоисточник:** [github.com/Dushnilin/tachyon-lists](https://github.com/Dushnilin/tachyon-lists)

Каталог списков одним файлом [`lists.json`](./lists.json) для подключения всех **146 категорий** проекта **Tachyon Lists** (37 списков IP-подсетей и 139 списков доменов) для zapret manager или splify2.

Роутер скачивает **только** `lists.json`, в котором перечислены все доступные категории, их русские названия и ссылки на скомпилированные наборы `.srs` из основного репозитория `Dushnilin/tachyon-lists`. При включении нужного сервиса в zapret manager или splify2 автоматически скачивает и раскрывает набор на домены и подсети.

---

## Подключить к своему роутеру

В **zapret manager** или **splify2**: **Настройки → Общее**, карточка **«Источник списков»**, вставить ссылку:

```text
https://github.com/H1rolce/tachyon-lists/releases/latest/download/lists.json
```

*(или прямую raw-ссылку: `https://raw.githubusercontent.com/H1rolce/tachyon-lists/main/lists.json`)*

Это же значение можно задать по SSH:

```sh
uci set splify2.main.manifest_url='https://github.com/H1rolce/tachyon-lists/releases/latest/download/lists.json'
uci commit splify2
```

---

## Что внутри `lists.json`

* **`categories` (37 списков подсетей)** — IP-диапазоны сервисов и платформ (Telegram, Discord, Cloudflare, CloudFront, Hetzner, OVH, DigitalOcean, GeoIP и др.).
* **`domain_lists` (139 списков доменов)** — доменные списки сервисов, нейросетей (OpenAI, Claude, Gemini, Grok, Cursor и др.), стриминга, игр, геоблока и региональных блокировок.
* **`same_as_ip` (30 связанных сервисов)** — сервисы, содержащие одновременно и домены, и подсети, объединены в интерфейсе одной строкой.

---

## Автоматическое обновление

Сборка запускается раз в сутки автоматически (`.github/workflows/lists.yml`) и обновляет `lists.json` и релиз только в том случае, если состав списков в источнике изменился.

Проверить или пересобрать локально (без внешних зависимостей, только Python 3.8+):

```sh
python3 build.py
```

---

## Первоисточники и благодарности

* **[Dushnilin/tachyon-lists](https://github.com/Dushnilin/tachyon-lists)** — автор и компилятор списков маршрутизации.
* **[splify2/splify2-lists](https://github.com/splify2/splify2-lists)** — спецификация формата каталога `lists.json` для zapret manager или splify2.
