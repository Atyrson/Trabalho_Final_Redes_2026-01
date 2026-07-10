

# Mini-IPTV Multicast com Controle de Banda WAN

## Sobre o Projeto

Este é um projeto de pesquisa desenvolvido para a disciplina de **Fundamentos de Redes de Computadores (FRC)** da **Universidade de Brasília (UnB) - Faculdade UnB Gama**.

O objetivo do sistema é explorar de forma prática as funcionalidades das camadas de rede e de aplicação do modelo TCP/IP, integrando conceitos de segurança, roteamento e gerência de tráfego. Para isso, foi construída uma infraestrutura de rede que suporta uma aplicação de **Mini-IPTV**, capaz de transmitir fluxos de vídeo via **multicast** para clientes locais (LAN) e clientes remotos limitados por um enlace WAN de baixa performance.

---

## Infraestrutura e Topologia de Rede

A arquitetura de rede do projeto simula a interconexão de duas redes locais isoladas através de um enlace serial ponto a ponto (PPP).

```
                [ Rede do Laboratório (Internet) ]
                                |
                                | (Source NAT)
                                v
  [ Host S ] ------------> [ Roteador R1 ] <=================> [ Roteador R2 ]
  (172.16.0.2)             (172.16.0.1)      Enlace WAN PPP     (192.168.0.1)
  - Backend/DB             (10.0.0.1)        (115200 bps)       (10.0.0.2)
  - VLC Server (Multicast) - Web Server/Proxy                   - DHCP Server
  - DNS / SMTP             - API Gateway                              |
        |                                                             |
        v                                                             v
[ Clientes Z e W ]                                            [ Clientes X e Y ]
  (Perfil LAN)                                                  (Perfil WAN115K)

```


* **Host S (Servidor de Aplicação e Streaming):** Configurado com IP estático, centraliza o backend da aplicação, banco de dados, servidores DNS e SMTP da intranet, e o processo emissor do VLC Server.



* **Roteador R1 (Gateway / Proxy Reverso):** Funciona como a borda da nossa intranet isolada. É o único nó conectado à rede externa do laboratório, provendo Source NAT para que as demais máquinas acessem a internet. Hospeda o servidor Apache HTTPD configurado como Proxy Reverso (API Gateway) com terminação TLS (HTTPS).



* **Roteador R2 (Servidor DHCP):** Interliga a ponta remota da WAN e distribui dinamicamente os endereços IP, rotas e configurações de rede para as estações da LAN #2.



* **Enlace WAN:** Conexão serial PPP artificialmente limitada à taxa de 115200 bps utilizando as ferramentas de Traffic Control (`tc`) do Linux.



---

## Arquitetura da Aplicação Mini-IPTV

A aplicação adota uma separação estrita entre o **Fluxo de Controle** (requisições administrativas, autenticação e listagem) e o **Fluxo de Mídia** (transmissão de pacotes de vídeo).

### Fluxo de Controle e Autenticação

1. O cliente abre a aplicação no navegador (Frontend em React) e efetua a autenticação.


2. A requisição via HTTPS (JSON/REST) bate no API Gateway em $R_1$, que valida o tráfego de borda e repassa a demanda internamente via HTTP para o backend no Host $S$.


3. O sistema valida as credenciais através de um mecanismo OAuth2/OIDC, emitindo um token JWT (JSON Web Token) que passa a assinar todas as interações subsequentes.



### Fluxo de Mídia e Regras de Concorrência

Quando um usuário autenticado solicita a reprodução de um canal, o backend gera uma playlist no formato `.m3u` adaptada ao perfil do usuário e orquestra o VLC Server (`cvlc`) em background para disparar o stream via UDP Multicast:


* **Perfil LAN (Hosts Z e W):** Usuários na rede de alta velocidade. Recebem o streaming com a qualidade original do vídeo através da faixa de endereços `239.10.x.x/16`. Clientes distintos podem assistir a canais diferentes simultaneamente nesta rede.



* **Perfil WAN115K (Hosts X e Y):** Usuários conectados após o enlace lento. Recebem a versão transcodificada de baixo bitrate através da faixa `239.20.x.x/16`.



* *Restrição Crítica:* Apenas **um** canal de vídeo pode trafegar pela WAN ao mesmo tempo. Se $X$ estiver assistindo ao Canal 1, $Y$ só poderá se inscrever no grupo multicast do Canal 1; tentativas de abrir outros canais são bloqueadas pelo backend para evitar o colapso do link de 115200 bps.





### Convenção de Endereçamento Multicast (`239.<perfil>.<grupo>.<canal>`)

Seguindo as especificações do projeto, os IPs de classe D são mapeados dinamicamente:


* **Perfil:** `10` para LAN e `20` para WAN115K.


  
* **Grupo:** Identificador único do grupo de desenvolvimento.



* **Canal:** ID do canal cadastrado.



---

## Divisão de Responsabilidades do Grupo

O desenvolvimento e os testes do projeto foram distribuídos de forma verticalizada entre os 5 integrantes:

* **Pessoa A:** Configuração física e lógica da rede, tabelas de roteamento IP e ativação do daemon de roteamento multicast (`pimd`/`smcroute`).
  
* **Pessoa B:** Implementação do servidor DHCP em $R_2$, e conteinerização dos serviços corporativos de DNS e SMTP (validando e-mails seguros via cliente Thunderbird).


  
* **Pessoa C:** Desenvolvimento do ecossistema Backend, modelagem do Banco de Dados, gerenciamento de sessões com OAuth2/JWT e regras de Proxy Reverso no Apache HTTPD.



* **Pessoa D:** Construção das interfaces Web (Frontend em React) para os Clientes e painel do Administrador, controle de persistência do token JWT e integração com o disparo do VLC Client através de arquivos `.m3u`.


* **Pessoa E:** Escrita de testes automatizados e de carga para os serviços, além de liderar a integração entre os subsistemas de rede e software.

---

## Tecnologias Utilizadas e Ferramentas


* **Frontend:** React, Tailwind CSS.


  
* **Roteamento e Rede:** Linux (Alpine/Ubuntu), `iptables` (Source NAT), `tc` (Traffic Control), `pimd` / `smcroute`.



* **Proxy / Web Server:** Apache HTTPD (`mod_proxy`, `mod_proxy_http`, `mod_ssl`).



* **Processamento de Mídia:** `ffmpeg` (para compressão do perfil WAN) e `ffprobe` (extração de metadados).



* **Streaming:** VLC Server (`cvlc`) e VLC Client (reprodutor nativo).



---

## Como Executar o Projeto

### 1. Preparação dos Vídeos (Módulo Admin)

O comando padrão utilizado pelo backend para transcodificar uploads automáticos para o perfil WAN de 115200 bps baseia-se em:

```bash
ffmpeg -i v_original.mp4 -c:v libx264 -b:v 80k -r 10 -s 320x240 -c:a aac -b:a 16k -ac 1 -ar 22050 v_wan.mp4

```

### 2. Configurando o Limite da WAN (Roteadores R1/R2)

Para simular o estrangulamento da linha de comunicação WAN nas interfaces seriais/artificiais:

```bash
sudo tc qdisc add dev <interface_wan> root tbf rate 1152kbit burst 32kbit lat 400ms

```

### 3. Executando o Frontend (Clientes X, Y, Z, W)

Certifique-se de que a máquina possui o Node.js instalado.

```bash
# Navegar até o diretório do app
cd frontend

# Instalar dependências (Tailwind CSS, Axios, etc.)
npm install

# Iniciar o servidor local de desenvolvimento
npm run dev

```

---

## Referências

* TANENBAUM, A.; WETHERALL, D. *Computer Networks*. Prentice Hall, 5ª Ed., 2011.


* Documentação Oficial do Apache HTTP Server (Reverse Proxy Guide).


* Ferramenta de Linha de Comando FFmpeg / FFprobe.
