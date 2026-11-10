<div align="center">

# tachyon-lists (`lists.json`)

**Каталог списков доменов и подсетей [Tachyon Lists](https://github.com/Dushnilin/tachyon-lists) для `steer` / `splify2` в Zapret Manager**

</div>

---

> [!IMPORTANT]
> **Автор исходных списков и компилятора:** [@Dushnilin](https://github.com/Dushnilin)  
> **Первоисточник:** [github.com/Dushnilin/tachyon-lists](https://github.com/Dushnilin/tachyon-lists)

Единый манифест [`lists.json`](./lists.json) для подключения всех **146 категорий** проекта **Tachyon Lists** (37 списков IP-подсетей и 139 списков доменов) в качестве каталога списков `steer` / `splify2` (в том числе в панели **Zapret Manager** на OpenWrt).

Роутер скачивает только компактный `lists.json`, в котором перечислены все категории, их русские названия и ссылки на бинарные наборы `.srs` из основного репозитория `Dushnilin/tachyon-lists`. При включении нужного сервиса ядро `steer` автоматически скачивает и распаковывает выбранный набор (`steer srs-read`).

---

## Подключение к роутеру

### 1. Через веб-интерфейс (Zapret Manager / splify2)

В разделе **Настройки → Общее**, карточка **«Источник списков»**, укажите ссылку:

```text
https://raw.githubusercontent.com/H1rolce/tachyon-lists/main/lists.json
```

*(или ссылку на релиз: `https://github.com/H1rolce/tachyon-lists/releases/latest/download/lists.json`)*

### 2. Через SSH (OpenWrt UCI)

```sh
uci set splify2.main.manifest_url='https://raw.githubusercontent.com/H1rolce/tachyon-lists/main/lists.json'
uci commit splify2
```

---

## Что внутри `lists.json`

* **`categories` (37 списков подсетей)** — IP-диапазоны сервисов и платформ (Telegram, Discord, Cloudflare, CloudFront, Hetzner, OVH, DigitalOcean, GeoIP и др.).
* **`domain_lists` (139 списков доменов)** — доменные списки сервисов, нейросетей (OpenAI, Claude, Gemini, Grok, Cursor и др.), стриминга, игр, геоблока и региональных блокировок.
* **`same_as_ip` (30 связанных сервисов)** — сервисы, содержащие одновременно и домены, и подсети, объединены в интерфейсе одной строкой.

---

## Списки для `sing-box` (Forkozz / NetShift)

Помимо каталога `lists.json` для `steer`, в разделе **[Releases (v1.0.0)](https://github.com/H1rolce/tachyon-lists/releases/tag/v1.0.0)** доступны готовые объединённые JSON-наборы правил (`Sing-box Rule Set v3`):

| Файл | Назначение | Прямая ссылка |
|:---|:---|:---|
| **`tachyon_proxy_ruleset.json`** | 125 категорий для маршрутизации в **Proxy / VPN** | [Скачать](https://github.com/H1rolce/tachyon-lists/releases/download/v1.0.0/tachyon_proxy_ruleset.json) |
| **`tachyon_direct_ruleset.json`** | 11 категорий прямого доступа (**Direct** / RU) | [Скачать](https://github.com/H1rolce/tachyon-lists/releases/download/v1.0.0/tachyon_direct_ruleset.json) |
| **`tachyon_block_ruleset.json`** | 10 категорий блокировки рекламы и угроз (**Block**) | [Скачать](https://github.com/H1rolce/tachyon-lists/releases/download/v1.0.0/tachyon_block_ruleset.json) |
| **`tachyon_unified_ruleset.json`** | Все 146 категорий в одном дедуплицированном Rule Set | [Скачать](https://github.com/H1rolce/tachyon-lists/releases/download/v1.0.0/tachyon_unified_ruleset.json) |

---

## Автоматическое обновление

Манифест `lists.json` автоматически синхронизируется с индексом [`Dushnilin/tachyon-lists`](https://github.com/Dushnilin/tachyon-lists) раз в сутки через GitHub Actions (`.github/workflows/lists.yml`). Для ручной пересборки:

```sh
python3 build.py
```

---

## Первоисточники и благодарности

* **[Dushnilin/tachyon-lists](https://github.com/Dushnilin/tachyon-lists)** — автор и компилятор списков маршрутизации.
* **[splify2/splify2-lists](https://github.com/splify2/splify2-lists)** — спецификация формата каталога `lists.json` для `steer`.
