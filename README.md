# API de Produtos — Cloudflare

API para cadastro de produtos construída sobre **Cloudflare Workers** com banco de dados **Cloudflare D1** (SQLite), cuja infraestrutura é provisionada com **Terraform**.

## Estrutura do projeto

```
.
├── api/          # API Express local (Node.js) — esqueleto inicial
├── terraform/    # Provisionamento do banco D1 na Cloudflare
└── worker/       # Cloudflare Worker com a API de produtos
    ├── migrations/   # Migrations SQL do D1
    ├── src/          # Código do Worker
    └── test/         # Testes (Vitest + @cloudflare/vitest-pool-workers)
```

| Diretório   | Descrição |
|-------------|-----------|
| `worker/`   | API principal. Roda na borda da Cloudflare e grava os produtos no D1 através do binding `DB`. |
| `terraform/`| Cria o banco D1 `produtos-db` na conta Cloudflare. |
| `api/`      | Servidor Express simples na porta `3000`, com apenas uma rota de status. |

## Pré-requisitos

- [Node.js](https://nodejs.org/) 18+ e npm
- [Terraform](https://developer.hashicorp.com/terraform/install)
- Conta na [Cloudflare](https://dash.cloudflare.com/) com um API Token com permissão de edição em **D1** e **Workers**

## 1. Infraestrutura (Terraform)

O provider da Cloudflare lê o token da variável de ambiente `CLOUDFLARE_API_TOKEN`.

```bash
cd terraform

export CLOUDFLARE_API_TOKEN="<seu-token>"

terraform init
terraform plan  -var="cloudflare_account_id=<seu-account-id>"
terraform apply -var="cloudflare_account_id=<seu-account-id>"
```

Também é possível criar um arquivo `terraform.tfvars` (já ignorado pelo Git):

```hcl
cloudflare_account_id = "<seu-account-id>"
```

### Variáveis

| Variável                | Descrição               | Obrigatória |
|-------------------------|-------------------------|-------------|
| `cloudflare_account_id` | ID da conta Cloudflare  | Sim         |

### Recursos criados

| Recurso                   | Nome          |
|---------------------------|---------------|
| `cloudflare_d1_database`  | `produtos-db` |

> Após o `apply`, confira se o `database_id` em `worker/wrangler.jsonc` corresponde ao ID do banco criado (visível no painel da Cloudflare ou via `npx wrangler d1 list`).

## 2. Worker

### Instalação

```bash
cd worker
npm install
```

### Migrations

Aplicar a migration no banco local (usado pelo `wrangler dev`):

```bash
npx wrangler d1 migrations apply produtos-db --local
```

Aplicar no banco remoto (produção):

```bash
npx wrangler d1 migrations apply produtos-db --remote
```

### Desenvolvimento local

```bash
npm run dev
```

O Worker fica disponível em `http://localhost:8787`.

### Deploy

```bash
npx wrangler login   # apenas na primeira vez
npm run deploy
```

### Testes

```bash
npm test
```

> **Atenção:** os testes em `worker/test/index.spec.js` ainda são os do template padrão ("Hello World!") e falham com a implementação atual. Eles precisam ser atualizados para refletir as rotas da API.

## Endpoints

### `GET /`

Verifica se a API está no ar. (Qualquer rota não mapeada também retorna esta resposta.)

```json
{ "mensagem": "API de produtos funcionando" }
```

### `POST /produtos`

Cadastra um novo produto.

**Corpo da requisição**

| Campo       | Tipo    | Obrigatório |
|-------------|---------|-------------|
| `nome`      | string  | Sim         |
| `descricao` | string  | Sim         |
| `categoria` | string  | Sim         |
| `preco`     | number  | Sim         |
| `imagem`    | string  | Não         |

**Exemplo**

```bash
curl -X POST http://localhost:8787/produtos \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Camiseta",
    "descricao": "Camiseta 100% algodão",
    "categoria": "Vestuário",
    "preco": 59.90,
    "imagem": "https://exemplo.com/camiseta.png"
  }'
```

**Resposta**

```json
{
  "mensagem": "Produto cadastrado com sucesso!",
  "id": 1
}
```

## Banco de dados

Tabela `produtos` (definida em `worker/migrations/0001_create-produtos.sql`):

| Coluna      | Tipo    | Restrições                  |
|-------------|---------|-----------------------------|
| `id`        | INTEGER | PRIMARY KEY AUTOINCREMENT   |
| `nome`      | TEXT    | NOT NULL                    |
| `descricao` | TEXT    | NOT NULL                    |
| `categoria` | TEXT    | NOT NULL                    |
| `preco`     | REAL    | NOT NULL                    |
| `imagem`    | TEXT    |                             |

## 3. API Express (opcional)

Servidor Node.js local, atualmente com apenas uma rota de status.

```bash
cd api
npm install
npm start
```

Disponível em `http://localhost:3000`:

```json
{ "mensagem": "API rodando..." }
```

## Tecnologias

- [Cloudflare Workers](https://developers.cloudflare.com/workers/)
- [Cloudflare D1](https://developers.cloudflare.com/d1/)
- [Wrangler](https://developers.cloudflare.com/workers/wrangler/)
- [Terraform](https://www.terraform.io/) + [Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Express](https://expressjs.com/)
- [Vitest](https://vitest.dev/)
