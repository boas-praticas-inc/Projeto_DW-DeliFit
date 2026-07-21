# DeliFit Data Warehouse

Projeto desenvolvido para a disciplina **Sistemas de Apoio à Decisão (SAD)** da Universidade Federal de Sergipe (UFS).

O objetivo do projeto é desenvolver um ambiente de **Data Warehouse** a partir de um sistema operacional (OLTP) para apoiar a tomada de decisão em uma plataforma de delivery de refeições saudáveis chamada **DeliFit**.

---

# Objetivos

Este projeto contempla todas as etapas propostas na disciplina:

- Modelagem do ambiente operacional (OLTP);
- Definição dos indicadores de negócio;
- Modelagem dimensional (Esquema Estrela);
- Projeto da Área de Staging;
- Desenvolvimento do processo ETL;
- Criação de agregados;
- Consultas de verificação;
- Construção de dashboards para análise dos indicadores.

---

# Tecnologias Utilizadas

- SQL Server
- T-SQL
- Modelagem Dimensional
- ETL
- Power BI
- Git
- GitHub

---

# Cenário

O DeliFit é uma plataforma digital responsável por intermediar pedidos entre clientes e restaurantes parceiros especializados em refeições saudáveis.

A partir dos dados operacionais do sistema são produzidos indicadores analíticos relacionados a:

- faturamento;
- pedidos;
- clientes;
- restaurantes;
- itens vendidos;
- categorias;
- pagamentos.

---

# Arquitetura

O projeto é dividido em três ambientes.

```text
            OLTP
              │
              ▼
           STAGING
              │
              ▼
      DATA WAREHOUSE
              │
              ▼
 Dashboard / Relatórios
```


---

# Ambiente OLTP

O ambiente operacional é composto pelas seguintes entidades:

- Usuários
- Clientes
- Endereços
- Restaurantes
- Categorias do Cardápio
- Itens do Cardápio
- Pedidos
- Itens do Pedido

---

# Ambiente Dimensional

## Fato

`dw.ft_venda` — uma linha por item de pedido.

## Dimensões

- Dim Tempo
- Dim Cliente
- Dim Restaurante
- Dim Endereço
- Dim Status
- Dim Item
- Dim Pagamento

## Agregados

- Vendas Diárias
- Vendas Mensais
- Vendas por Restaurante
- Vendas por Categoria
- Vendas por Cliente

---

# Indicadores

O Data Warehouse permite análises como:

## Financeiro

- Faturamento diário
- Faturamento mensal
- Faturamento anual
- Ticket médio
- Receita por categoria
- Receita por restaurante

## Pedidos

- Quantidade de pedidos
- Pedidos por status
- Tempo médio de entrega
- Taxa de cancelamento

## Clientes

- Clientes cadastrados
- Clientes que mais compram
- Clientes que mais gastam
- Ticket médio por cliente

## Produtos

- Itens mais vendidos
- Categorias mais vendidas

## Pagamentos

- Pedidos por forma de pagamento
- Taxa de pagamentos concluídos
- Taxa de falha de pagamento

---

# Processo ETL

O fluxo ETL é composto pelas seguintes etapas:

1. Extração dos dados do ambiente OLTP;
2. Carga para a Área de Staging;
3. Tratamento e validação dos dados;
4. Carga das dimensões;
5. Carga da tabela fato;
6. Atualização dos agregados.

## Como rodar o projeto

### Regras atuais do ETL

As regras de qualidade ficam centralizadas em `dw.sp_validar_staging`.
Essa procedure gera um `lote_execucao`, registra as violações em
`violacao.ft_venda_violacao` e o mesmo lote é enviado para
`dw.sp_carregar_ft_venda`. A fato carrega somente pedidos e itens sem
violação naquele lote.

As dimensões SCD Tipo 2 são associadas à fato pela versão válida na data do
pedido. Pedidos cancelados permanecem na fato para análises operacionais,
mas são excluídos dos agregados e indicadores financeiros.

O projeto utiliza SQL Server. Os scripts devem ser executados no SQL Server
Management Studio ou pelo `sqlcmd`, respeitando a ordem abaixo.

### 1. Criar a estrutura do banco

Execute os arquivos da pasta `scripts_banco/ddl` nesta ordem:

1. `00_banco_e_schemas.sql`;
2. `01_oltp_tabelas.sql`;
3. `02_dw_tabelas.sql`;
4. `03_staging_tabelas.sql`;
5. `04_violacoes.sql`;
6. `05_agregados.sql`;
7. `06_views.sql`.


### 2. Criar e povoar o ambiente operacional

Execute:

1. `scripts_banco/povoamento_operacional.sql`;
2. `scripts_banco/povoamento_dimensao_tempo.sql`.

### 3. Criar as procedures

Execute os arquivos abaixo para criar as procedures, sem executar cargas
automaticamente:

1. `scripts_banco/procedimentos_oltp/procedimentos_oltp.sql`;
2. `scripts_banco/procedimentos_violacao/procedimentos_violacao.sql`;
3. `scripts_banco/procedimentos_dw/procedimentos_dw_dimensoes.sql`;
4. `scripts_banco/procedimentos_dw/procedimento_dw_fato.sql`;
5. `scripts_banco/procedimentos_dw/procedimentos_agregado.sql`.

### 4. Executar o ETL

Execute o arquivo `scripts_banco/execucao/executar_etl.sql`. Ele realiza,
na ordem, a extração Full Load para a staging, a validação, a carga das
dimensões, a carga da fato e a atualização dos agregados.

### 5. Conferir os indicadores

Depois do ETL, execute:

`scripts_banco/verificacao/consultas_verificacao_indicadores.sql`

Os arquivos de definição apenas criam tabelas e procedures. As execuções
foram separadas em scripts próprios para evitar cargas acidentais ao abrir ou
reexecutar um arquivo de definição.

---

# Dashboard

Os dados armazenados no Data Warehouse serão disponibilizados em dashboards desenvolvidos no Power BI, permitindo análises gerenciais e apoio à tomada de decisão.

---

# Equipe

| Integrante | GitHub |
|------------|--------|
| Paulo Henrique Oliveira Santos | @PauloHenrique1O |
| Kauan Brilhante | @KauanFBR |
| Matheus Calixto | @MatheusCalixto42 |
| Leandro Carvalho | @LeandroMCarv |

---

# Licença

Projeto desenvolvido exclusivamente para fins acadêmicos na disciplina **Sistemas de Apoio à Decisão (SAD)** da Universidade Federal de Sergipe.
