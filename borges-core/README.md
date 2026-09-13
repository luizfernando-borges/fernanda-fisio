---
id: README_Borges_Core
tipo: GOVERNANCE
titulo: README — Borges Core
status: ativo
versao: v1
criado_em: 2026-07-02
---

# Borges Core

Se você é novo aqui, este documento existe para você entender todo o Borges Core em menos de 30 minutos. Leia na ordem — cada seção assume a anterior.

## 1. O que é isto, em uma frase (2 min)

O Borges Core **não é um software**. É o patrimônio intelectual da Borges Performance: tudo que a empresa sabe sobre marketplace, e-commerce, logística, operação e consultoria, organizado para ser consumido por qualquer produto do ecossistema — hoje o Centro de Inteligência, no futuro o Maestro WMS, a IA Borges, o Aplicativo e outros.

**Nenhum produto tem conhecimento próprio.** Toda inteligência vem daqui. Os produtos apenas executam.

## 2. A regra de ouro (2 min)

> Nenhuma tela nasce antes da pergunta que ela responde.

O sistema não começa por dashboard. Começa por uma **Business Question** — uma pergunta real que um empresário faz ("Como está minha empresa hoje?", "Onde estou perdendo dinheiro?"). Toda funcionalidade, de qualquer produto, nasce de uma pergunta catalogada aqui — nunca de "vamos fazer um gráfico de X".

## 3. Os 5 Pilares (5 min)

| Pilar | O que é |
|---|---|
| **Business Questions** | As perguntas que empresários fazem diariamente — o coração do sistema |
| **Facts** | Os fatos: dados de Bling, Mercado Livre, Shopee, Google Sheets, Maestro. Nunca interpreta, nunca recomenda — só registra |
| **Knowledge** | O conhecimento que explica os fatos: frameworks administrativos, marketplace, operações, consultoria Borges |
| **Playbooks** | O DNA operacional de cada cliente — como Blowback, HGZ, Classe Couro, Pedrosa e Megaju realmente trabalham |
| **Learning** | O aprendizado contínuo — cada decisão do cliente e cada resultado obtido fortalece o método para todos |

Existe uma sexta camada, o **Business Engine**, que não é um pilar — é o mecanismo que consome os quatro primeiros pilares para produzir Rules (regras), Models (cálculo de confiança), Recommendations, Insights, Alerts e Actions.

## 4. Como uma pergunta vira uma recomendação (5 min)

```
Business Question → Facts + Knowledge + Playbooks → Business Engine
  → aplica Rules → calcula confiança (Model) → gera Recommendation
  → mostra evidências → Insight / Alert / Action → resultado → Learning
```

Uma recomendação nunca é uma afirmação seca. Sempre vem como *"Minha recomendação é..."* ou *"Com base nos dados disponíveis..."*, sempre com evidências, conceitos usados, grau de confiança, resultado esperado e como validar a hipótese. Quem decide continua sendo o gestor — o sistema recomenda, nunca substitui.

## 5. Como o repositório é organizado (5 min)

```
/01-business-questions   as perguntas
/02-facts                 dicionário de dados, nunca os dados em si
/03-knowledge              conceitos e frameworks
/04-playbooks               genéricos e por cliente
/05-business-engine          rules, models, recommendations, prompts, insights, alerts, actions
/06-learning                   casos reais e decisões de método
/07-clients                     perfil de cada cliente (não duplica playbook/KPI, só referencia)
/08-products                      o que cada produto consome do Core
/09-templates                      os 15 templates oficiais
```

Detalhe completo, com a função de cada pasta, em `GOVERNANCE_Arquitetura_Borges_Core.md`.

## 6. Como criar um documento novo (5 min)

1. Identifique o tipo (Business Question? Knowledge? Rule?) — os 15 tipos estão em `TEMPLATES_OFICIAIS.md`
2. Copie o template correspondente
3. Nomeie o arquivo como `{ID}_{Slug_Em_Title_Case}.md` — ex.: `RULE_014_Queda_Conversao.md`
4. Preencha o front-matter, inclusive `relacionados` com os IDs de qualquer outro documento que este referencia
5. Nunca copie conteúdo de outro documento — referencie pelo ID

Regras completas de nomenclatura, numeração e códigos de cliente/produto/domínio em `GOVERNANCE_Arquitetura_Borges_Core.md`, seção 2.

## 7. Por onde começar, dependendo do seu papel (5 min)

- **Se você vai desenvolver um produto:** comece por `/08-products/{SEU_PRODUTO}/` — é o que seu produto deve consumir daqui. Nunca escreva conhecimento de negócio dentro do código do produto.
- **Se você é consultor e está com um cliente novo:** comece por `/07-clients/` para o perfil, depois `/04-playbooks/clientes/` para registrar o DNA operacional dele.
- **Se você identificou uma pergunta recorrente de cliente:** vá direto para `/01-business-questions` e crie uma `BQ`, mesmo que ainda não tenha resposta pronta.
- **Se você está formalizando um conceito ou framework:** vá para `/03-knowledge`.

## 8. O que nunca fazer aqui

- Nunca criar uma tela sem uma Business Question por trás
- Nunca criar uma recomendação sem evidências
- Nunca afirmar uma verdade quando existir apenas hipótese
- Nunca duplicar conteúdo entre documentos — sempre referenciar por ID
- Nunca colocar conhecimento de negócio dentro do código de um produto

Isso é o suficiente para começar. O resto do repositório existe para ser consultado quando a dúvida específica aparecer — não para ser lido inteiro de uma vez.
