# HortWiz QoL V2

![Project Zomboid](https://img.shields.io/badge/Project%20Zomboid-B42-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Performance](https://img.shields.io/badge/Performance-O(1)-brightgreen)

Suite de **Quality of Life (QoL)** para o Project Zomboid Build 42, desenhada a partir do zero com **performance extrema** em mente. Nada de loops em `OnTick`, nada de quedas de FPS.

## Requer
- **HortWiz Core** (dependência obrigatória — logger, debug panel e utilitários compartilhados).

## Features
- **Rip All Clothing:** Rasgue toda a roupa elegível do inventário de uma vez, com gating de ferramenta (Scissors/Sharp Knife) por tipo de tecido.
- **Dismantle All Electronics:** Desmonte todos os eletrônicos elegíveis de uma vez, dirigido pelas receitas de craft nativas do jogo (herda animação/XP/itens bônus automaticamente).
- **Zombie Outline:** Contorno de cor customizável para zumbis alvo.
- **Inventory Title:** Cabeçalho do inventário mostra `[Nome do Jogador]'s Inventory`.
- **Gas Siphon Walk:** Abasteça/sifone gasolina enquanto anda/mira, sem cancelar a ação.
- **Fence Interaction Priority:** Prioriza pular cercas sobre interações com itens no chão.
- **Worn Items Toggle:** Oculta roupas equipadas preservando slots de mochila/chaveiro.
- **Auto Equip Broken Weapon:** Reequipa automaticamente uma arma do mesmo tipo quando a atual quebra.
- **Walk & Equip:** Permite equipar/ajustar roupas enquanto anda ou mira.
- **Auto Unset Alarms:** Desativa alarmes de relógios/despertadores automaticamente ao looter.

## Instalação (Manual)
1. Baixe o último `.zip` da aba [Releases](../../releases).
2. Extraia a pasta `hortWiz_QoL_V2` dentro de `C:\Users\SEU_USUARIO\Zomboid\mods\`.
3. Instale também o **HortWiz Core** (dependência).
4. Ative os dois mods no menu principal do jogo.

## Configuração
O mod suporta **ModOptions** (opcional, soft-dependency). Se o ModOptions estiver instalado, você ganhará uma aba dedicada nas configurações do jogo para ligar/desligar cada recurso.

## Contribuição
Leia o [CONTRIBUTING.md](CONTRIBUTING.md) antes de enviar Pull Requests. Nós levamos a performance MUITO a sério. Qualquer código com *Vibe Coding* (loops desnecessários no render) será rejeitado.
