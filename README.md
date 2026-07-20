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

- Fato Vendas

## Dimensões

- Dim Tempo
- Dim Cliente
- Dim Restaurante
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
