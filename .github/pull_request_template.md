## Descrição

<!-- O que essa mudança faz, e por quê. -->

## Complexidade algorítmica

<!-- Obrigatório, conforme CONTRIBUTING.md. Ex: "Isso roda em O(1) via Monkeypatch no arquivo X." -->

## Checklist

- [ ] Nenhum loop pesado (`pairs`, buscas em `cell:getZombieList()`, etc.) em hooks de alta frequência (`OnTick`, `OnPlayerUpdate`, `prerender`).
- [ ] Nomenclatura segue `snake_case`/`_snake_case` (sem `camelCase`/`PascalCase` em locals/functions privadas).
- [ ] Testado em Debug Mode in-game.
