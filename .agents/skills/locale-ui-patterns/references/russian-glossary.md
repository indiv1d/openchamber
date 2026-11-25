# Russian glossary

Short developer style. The English source is the truth; the Russian text must stay shorter and more specific.

## Rules

- A button is one verb, one to three words: «Сохранить», «Закоммитить», «Создать PR».
- A switch is an action: «Разрешить агенту…», «Показывать…», «Останавливать…».
- A label is a noun phrase without officialese: «Обновить статистику», not «Обновить данные об использовании».
- A description is one or two short sentences. Remove «является», «позволяет», «вы можете», «необходимо» when a direct phrase works.
- Address the user as «вы», but drop the pronoun when the sentence works without it: «Выберите», «Можно применить».
- Use English developer terms where the Russian form is longer and developers say the English one.
- Keep the base vocabulary Russian: сессия, проект, ветка, коммит, провайдер, агент, модель, токен, навык, расширение, плагин, панель, вкладка, чат.

## Terms

| English | Russian |
| --- | --- |
| pull request | PR |
| merge request | MR |
| push | Push |
| pull | Pull |
| fetch | Fetch |
| rebase | rebase |
| stash | Stash |
| merge | Merge |
| commit | коммит, закоммитить |
| branch | ветка |
| remote | remote |
| upstream | upstream |
| worktree | worktree |
| diff | дифф |
| sidebar | сайдбар |
| panel | панель |
| tab | вкладка |
| session | сессия |
| turn | ход |
| prompt | запрос |
| provider | провайдер |
| agent | агент |
| subagent | субагент |
| lead session | ведущая |
| skill | навык |
| extension | расширение |
| plugin | плагин |
| token | токен |
| model | модель |
| workspace | рабочая область |

## Examples

| English | Russian |
| --- | --- |
| Turn stats | Метрики хода |
| Previous turn | Прошлый ход |
| Whole turn | Весь ход |
| Create draft PR | Создать черновик PR |
| Stash popped | Stash извлечён |
| Pull (rebase) | Pull (rebase) |
| Toggle sidebar | Переключить сайдбар |
| Refresh usage | Обновить статистику |
| Desktop UI password | Пароль приложения |
| Open in desktop app | Открыть в приложении |
| Stage files to enable commit. | Добавьте файлы в индекс, чтобы создать коммит. |
| Let the agent list this folder's terminals | Разрешить агенту видеть терминалы этой папки |
| You can apply or discard its changes. | Изменения можно применить или отменить. |
| This file is not a supported VS Code color theme. | Этот файл не поддерживается как тема VS Code. |
| Branch to rebase onto | Ветка для rebase |

## Keep as written

Product names, `MCP`, `API`, `SSE`, `WebSocket`, `HTTP`, `SSH`, `URL`, file paths, commands, flags, environment variables, keyboard chords, model and provider names, and user content.

## Plural forms

Use the count-first form for `Single` and `Plural` pairs: «Сессий: {count}». Use `one`, `few`, `many`, `other` in ICU plural messages.
