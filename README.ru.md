# fsemver

**Парсер и матчер semver-требований для Forth.** Операторы в стиле
Hex/Elixir: `~>`, `>=`, `==`, `>`, `<`, `<=` и голое `X.Y.Z`. Один
файл, одна зависимость для тестов (ttester), ноль runtime-зависимостей.

Часть **VitaSound Forth tooling family** —
[fmix](https://github.com/VitaSound/fmix),
[flint](https://github.com/VitaSound/flint),
[ttester](https://github.com/VitaSound/ttester),
[fenum](https://github.com/VitaSound/fenum).

## Зачем отдельная либа

И fmix (`fmix_version_check.4th`), и flint (`flint/version-check.4th`)
читают строку требования к версии из проектного `package.4th`,
парсят её и проверяют, удовлетворяет ли установленный инструмент.
Алгоритм небольшой (~100 строк), но копировать его в третий тул
(fcov, …) — путь к расхождениям. fsemver — единственный источник
истины.

## Установка

```bash
cd ~ && git clone git@github.com:VitaSound/fsemver.git
cd fsemver && fmix packages.get
```

fsemver — это библиотека, не CLI. Никакого `bin/`-лаунчера, никаких
правок `~/.bashrc`.

Для своего проекта добавьте в `package.4th`:

```forth
key-list dependencies fsemver git https://github.com/VitaSound/fsemver tag 0.1.0
```

потом `fmix packages.get` положит её в `forth-packages/fsemver/0.1.0/`.
В Forth-коде:

```forth
require forth-packages/fsemver/0.1.0/fsemver.4th
```

## Операторы

| Запись      | Что означает                                       |
|-------------|----------------------------------------------------|
| `~> X.Y`    | `>= X.Y.0`   и   `< (X+1).0.0`                     |
| `~> X.Y.Z`  | `>= X.Y.Z`   и   `<  X.(Y+1).0`                    |
| `>= X.Y.Z`  | минимум, без верхней границы                       |
| `==  X.Y.Z` | ровно эта версия                                   |
| `>  X.Y.Z`  | строго больше                                      |
| `<  X.Y.Z`  | строго меньше                                      |
| `<= X.Y.Z`  | меньше-или-равно                                   |
| `X.Y.Z`     | голая = синоним для `>= X.Y.Z`                     |

Операторы матчатся **по длиннейшему совпадению** (`~>`, `>=`, `<=`,
`==` раньше односимвольных `>` / `<`). Пробелы вокруг оператора
терпятся.

## API

```forth
fsemver.parse-version-parts ( a u -- ma mi pa n-parts )
    \ Парсит "X[.Y[.Z]]". Отсутствующие компоненты дефолтятся в 0.
    \ n-parts ∈ {0,1,2,3} — 0 значит «ничего не распарсилось».

fsemver.semver-cmp ( a-ma a-mi a-pa  b-ma b-mi b-pa -- {-1|0|1} )
    \ Численное (не лексикографическое) сравнение двух semver-троек.
    \ -1: a<b, 0: a==b, 1: a>b. (10 > 9, НЕ 10 < 9.)

fsemver.parse-req ( a u -- op ma mi pa valid? )
    \ Парсит строку требования. `op` — одна из fsemver.op-*-констант.
    \ valid? = false на ошибку парсинга (тогда ma/mi/pa = 0).

fsemver.req-matches? ( rma rmi rpa rop  sma smi spa -- f )
    \ True, если установленная semver-тройка `s*` удовлетворяет
    \ требованию `r* op`.
```

Константы операторов (возвращаются `parse-req`, потребляются
`req-matches?`):

```forth
fsemver.op-tilde-2     \  ~> X.Y
fsemver.op-tilde-3     \  ~> X.Y.Z
fsemver.op-gte         \  >= X.Y.Z  (и голое X.Y.Z)
fsemver.op-eq          \  == X.Y.Z
fsemver.op-gt          \  >  X.Y.Z
fsemver.op-lt          \  <  X.Y.Z
fsemver.op-lte         \  <= X.Y.Z
```

## Пример

```forth
require fsemver.4th

\ Проект пинит себя как `~> 0.7`, у нас установлено 0.7.4:
s" ~> 0.7" fsemver.parse-req      \ ( 0 0 7 0 true )
s" 0.7.4"  fsemver.parse-version-parts drop  \ ( 0 7 4 )
\ На стеке: rma rmi rpa rop sma smi spa
fsemver.req-matches? .            \ -1  (true: 0.7.4 подходит под ~> 0.7)
```

Боевая обвязка (взято из fmix 0.7.1 / flint 0.2.1):

```forth
\ Проект сказал `key-value fmix ~> 0.7`. У нас стоит fmix 0.6.5:
s" ~> 0.7" fsemver.parse-req { rop rma rmi rpa rok }
rok 0= IF ." invalid requirement" cr EXIT THEN

s" 0.6.5" fsemver.parse-version-parts drop { sma smi spa }

rma rmi rpa rop sma smi spa fsemver.req-matches? 0= IF
    ." installed fmix doesn't satisfy ~> 0.7" cr
THEN
```

## Тесты

```bash
fmix test
```

71 unit-кейс: parse-version-parts, semver-cmp, parse-req для каждого
оператора, req-matches? truth-table для каждого оператора.

## Дизайн

- **Один плоский файл** (~210 строк). Разделить на `parse.4th` /
  `req.4th` / `cmp.4th` — рассматривал и отверг: целиком файл короче,
  чем этот README.
- **Терпимый парсер.** Мусор на входе => `valid? = false`, никаких
  `throw` и `bye`. Вызывающие инструменты сами решают, WARN это
  (flint, soft-check) или жёсткий ERROR (fmix, build-gate).
- **Никаких внешних зависимостей в runtime.** Только ttester для тестов.
- **Чистый ANS Forth** где возможно; единственный Gforth-изм —
  локали (`{ a b c -- }`), которыми пронизан весь код.

## Публикация на theforth.net

[theforth.net](https://theforth.net/) — официальный реестр
Forth-пакетов. fsemver — крошечная либа без внешних рантайм-зависимостей,
идеально ложится туда.

Краткая инструкция (по [guidelines](https://theforth.net/guidelines)):

1. Создай аккаунт: <https://theforth.net/profile>.

2. Проверь `package.4th` — у fsemver он уже под guidelines:
   обязательные поля (`name`, `version`, `license`, `main`) и
   желательные (`description`, `tags`).

3. Собери архив. **Корневая папка в архиве должна точно совпадать с
   полем `name`** (`fsemver`), и `package.4th` лежит в её корне:

   ```bash
   cd ~                                          # на уровень выше fsemver/
   tar czf fsemver-0.1.0.tar.gz \
       --exclude='fsemver/.git' \
       --exclude='fsemver/forth-packages' \
       --exclude='fsemver/build' \
       fsemver
   ```

4. Залогинься на theforth.net, перейди в
   [Profile](https://theforth.net/profile) и загрузи архив через форму
   upload.

5. После публикации НЕ меняй `version` для уже выложенного слота —
   повышай его по SemVer:
   - **PATCH** — обратно-совместимый багфикс,
   - **MINOR** — обратно-совместимое добавление функциональности,
   - **MAJOR** — несовместимое изменение API.

## Лицензия

[COPL](LICENSE) — Communist Public License. Используйте свободно,
делитесь с другими.
