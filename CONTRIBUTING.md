# Contributing to HortWiz QoL V2

Agradecemos o seu interesse em contribuir para o nosso mod!
Nós levamos **Performance** a sério. Para que seu Pull Request seja aceito, você deve seguir estritamente as regras abaixo.

## Padrões de Código (Anti Vibe-Coding)

1. **Complexidade O(1):**
   - Não use loops pesados (como `pairs` em listas longas ou buscas no `cell:getZombieList()`) dentro de hooks de alta frequência como `Events.OnTick`, `Events.OnPlayerUpdate` ou `ISInventoryPage:prerender`.
   - Se precisar de filtros, crie um **cache na inicialização** e acesse em $O(1)$ através de HashMaps (tabelas Lua onde a chave é o item).

2. **UI Nativa > ModOptions:**
   - Evite forçar lógicas complexas (como listas e multi-telas) dentro das caixas genéricas do ModOptions.
   - Construa UIs limpas herdando de `ISPanel` / `ISUIElement`.
   - ModOptions deve ser apenas uma dependência "Soft" (opcional) para chaves de liga/desliga simples.

3. **Nomenclatura (Strict):**
   - Variáveis locais: `snake_case`.
   - Variáveis globais de módulo ou funções privadas: `_snake_case`.
   - NUNCA use `camelCase` ou `PascalCase`.

## Como enviar alterações
1. Faça um Fork do projeto.
2. Crie sua Feature Branch baseada no Padrão Conventional Commits (ex: `feat/minha-feature` ou `fix/meu-bug`).
3. Submeta o PR descrevendo claramente qual a complexidade algorítmica da sua alteração (ex: "Isso roda em $O(1)$ via Monkeypatch no arquivo X").
