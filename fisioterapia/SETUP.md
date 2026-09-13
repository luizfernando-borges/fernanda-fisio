# Guia de Configuração — Site Dra. Fernanda Rodrigues

Este guia leva você do zero até o site publicado em menos de 1 hora.

---

## Visão geral do sistema

```
GitHub (código) → Vercel (hospedagem) → Supabase (banco de dados + autenticação)
```

- **GitHub**: onde o código fica salvo
- **Vercel**: publica o site automaticamente a cada atualização
- **Supabase**: cuida do login, dados dos pacientes e arquivos

---

## Passo 1 — Criar conta no Supabase

1. Acesse [supabase.com](https://supabase.com) e clique em **Start your project**
2. Crie conta com Google ou e-mail
3. Clique em **New project**
4. Preencha:
   - **Name**: `fernanda-fisio` (ou qualquer nome)
   - **Database Password**: anote essa senha! (você vai precisar depois)
   - **Region**: South America (São Paulo)
5. Aguarde ~2 minutos enquanto o projeto é criado

### 1.1 Copiar as credenciais

No painel do Supabase, vá em **Settings → API**:

- Copie a **Project URL** (ex: `https://abcdef.supabase.co`)
- Copie a **anon / public** key (começa com `eyJhbGci...`)

Abra o arquivo `app/config.js` e substitua:

```js
const SUPABASE_URL = 'https://SEU-PROJETO.supabase.co'; // ← cole a Project URL
const SUPABASE_KEY = 'SUA-ANON-KEY-AQUI'; // ← cole a anon key
const ADMIN_EMAIL = 'fernanda@email.com'; // ← e-mail da Fernanda
```

### 1.2 Criar o banco de dados

1. No Supabase, vá em **SQL Editor**
2. Clique em **New query**
3. Abra o arquivo `app/schema.sql` deste projeto
4. Copie todo o conteúdo e cole no editor
5. **Antes de rodar**, localize as 4 linhas com `'fernanda@email.com'` e substitua pelo e-mail real da Fernanda
6. Clique em **Run** (▶)

Se aparecer "Success. No rows returned", funcionou.

### 1.3 Cadastrar a Fernanda no sistema de autenticação

1. Vá em **Authentication → Users**
2. Clique em **Add user → Create new user**
3. E-mail: o e-mail real da Fernanda
4. Senha: crie uma senha segura e anote

---

## Passo 2 — Criar conta no GitHub

1. Acesse [github.com](https://github.com) e crie uma conta (gratuita)
2. Clique em **New repository** (botão verde)
3. Preencha:
   - **Repository name**: `fernanda-fisio`
   - Marque **Private** (site privado por enquanto)
4. Clique em **Create repository**

### 2.1 Fazer upload dos arquivos

Na página do repositório recém-criado:

1. Clique em **uploading an existing file**
2. Arraste a pasta inteira `fisioterapia/` para a área de upload
3. Clique em **Commit changes**

> Se preferir usar Git pela linha de comando, é mais rápido e permite atualizações fáceis.

---

## Passo 3 — Publicar no Vercel

1. Acesse [vercel.com](https://vercel.com) e crie conta com GitHub
2. Clique em **Add New → Project**
3. Selecione o repositório `fernanda-fisio`
4. Clique em **Deploy**

O Vercel vai detectar que é um site HTML estático e publicar automaticamente.

Em ~1 minuto você recebe uma URL como:

```
https://fernanda-fisio.vercel.app
```

### 3.1 Domínio personalizado (opcional)

Para usar um domínio próprio como `dra-fernanda.com.br`:

1. No painel da Vercel, vá em **Settings → Domains**
2. Digite o domínio e siga as instruções de configuração DNS
3. Registre o domínio em [registro.br](https://registro.br) ou [godaddy.com](https://godaddy.com)

---

## Passo 4 — Cadastrar pacientes

1. A Fernanda acessa `seu-site.vercel.app/app/login`
2. Faz login com o e-mail e senha cadastrados no Passo 1.3
3. No painel admin, clica em **Novo Paciente**
4. Preenche nome, e-mail, diagnóstico, etc.

### Criar acesso para o paciente

O paciente precisa de uma conta no Supabase para acessar a área dele:

1. No Supabase, vá em **Authentication → Users → Add user**
2. Cadastre o e-mail do paciente com uma senha temporária
3. No admin, copie o **User ID** que aparece na lista de usuários
4. No painel da Dra. Fernanda, ao cadastrar o paciente, o campo **user_id** vincula automaticamente

> **Dica**: para simplificar, use a opção de "Magic Link" — o paciente recebe um e-mail e acessa sem precisar de senha.

---

## Passo 5 — Atualizar o site depois

Sempre que quiser mudar algo no site:

1. Edite os arquivos localmente
2. Abra o GitHub, vá ao repositório
3. Clique no arquivo → ícone de lápis (✏️) → edite → **Commit changes**
4. O Vercel republica automaticamente em ~30 segundos

---

## Estrutura de arquivos

```
fisioterapia/
├── index.html          ← site principal (4 páginas + agenda)
├── vercel.json         ← configuração de rotas do Vercel
├── SETUP.md            ← este guia
├── foto-hero.jpg.png   ← foto da Fernanda (banner)
├── foto-sobre.jpg.png  ← foto da Fernanda (seção sobre)
├── clinica-fisio-jpg.png ← foto da clínica
└── app/
    ├── config.js       ← ⚠️ PREENCHER com suas credenciais
    ├── schema.sql      ← ⚠️ RODAR no Supabase SQL Editor
    ├── login.html      ← página de login
    ├── admin.html      ← painel da Fernanda
    └── paciente.html   ← área do paciente
```

---

## Checklist final

- [ ] Supabase: projeto criado e credenciais copiadas para `config.js`
- [ ] `schema.sql` executado com o e-mail correto da Fernanda
- [ ] Fernanda cadastrada em Authentication → Users
- [ ] Arquivos enviados para o GitHub
- [ ] Site publicado no Vercel e acessível pela URL
- [ ] Login da Fernanda testado → redirecionamento para painel admin
- [ ] Cadastro de 1 paciente teste e validação da área do paciente

---

## Suporte e dúvidas

Para dúvidas técnicas:

- **Supabase docs**: [supabase.com/docs](https://supabase.com/docs)
- **Vercel docs**: [vercel.com/docs](https://vercel.com/docs)
