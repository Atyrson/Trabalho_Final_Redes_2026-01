# 1. Serviço DHCP

## 1.1 Introdução

O DHCP (*Dynamic Host Configuration Protocol*) é o protocolo responsável por
atribuir endereços IP de forma automática aos dispositivos de uma rede. Em vez
de configurar manualmente cada máquina, o servidor DHCP recebe as requisições
dos clientes e fornece as configurações necessárias — endereço IP, máscara de
sub-rede, gateway padrão e servidores DNS. Nesta seção são descritos os passos
para instalar e configurar o servidor DHCP da empresa **PipeVendas** em uma
estação da bancada, bem como os testes realizados para verificar o correto
funcionamento do serviço.

O servidor DHCP foi planejado para o endereço fixo **192.168.10.4**, dentro da
rede **192.168.10.0/24**, distribuindo aos clientes a faixa **192.168.10.100 –
192.168.10.200** e informando o gateway (**192.168.10.254**) e o servidor DNS
do grupo (**192.168.10.2**).

> **Observação sobre as ferramentas (o roteiro é antigo):** o roteiro original
> cita o pacote `dhcp3-server`, o arquivo `/etc/dhcpd.conf` e o comando
> `/etc/init.d/dhcpd3-server start`. Nas versões atuais do Ubuntu/Debian esses
> itens mudaram. Foram utilizados os equivalentes atuais:
>
> | Roteiro antigo | Utilizado neste trabalho |
> |---|---|
> | pacote `dhcp3-server` | `isc-dhcp-server` |
> | `/etc/dhcpd.conf` | `/etc/dhcp/dhcpd.conf` |
> | `/etc/init.d/dhcpd3-server start` | `systemctl restart isc-dhcp-server` |
> | `/etc/default/dhcp3-server` (interface) | `/etc/default/isc-dhcp-server` (`INTERFACESv4`) |
> | cliente `dhclient` | no Ubuntu 24.04 não é instalado por padrão; usamos `dhclient`/`udhcpc` conforme o ambiente |

---

## 1.2 Configuração do servidor

### Instalação

```bash
sudo apt update
sudo apt install -y isc-dhcp-server
```

### Arquivo principal: `/etc/dhcp/dhcpd.conf`

Toda a configuração do serviço fica neste arquivo:

```conf
# ===== Configuração DHCP - PipeVendas =====

# Tempos de concessão (lease), em segundos
default-lease-time 600;     # 10 min
max-lease-time 7200;        # 2 horas

# Este servidor é a autoridade oficial de DHCP nesta rede:
# corrige clientes com endereços incoerentes (envia DHCPNAK).
authoritative;

# Opções globais entregues a todos os clientes
option subnet-mask 255.255.255.0;
option broadcast-address 192.168.10.255;
option routers 192.168.10.254;             # gateway / roteador
option domain-name-servers 192.168.10.2;   # servidor DNS do grupo
option domain-name "pipevendas.com.br";

# Sub-rede da intranet
subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.100 192.168.10.200;
    option routers 192.168.10.254;
    option domain-name-servers 192.168.10.2;
    option domain-name "pipevendas.com.br";
}

# Reserva por MAC: uma estação conhecida recebe sempre o mesmo IP
host estacao-fixa {
    hardware ethernet 08:00:27:aa:bb:cc;   # MAC da estação
    fixed-address 192.168.10.50;
    option host-name "estacao1";
}
```

A faixa ofertada (`.100`–`.200`) foi escolhida de modo a **não conflitar** com
os IPs fixos dos servidores da infraestrutura (`.2` DNS, `.3` WWW, `.4` DHCP,
`.5` SMTP e `.254` roteador).

### Definição da interface de escuta

Para o serviço atender apenas na placa da rede interna, edita-se
`/etc/default/isc-dhcp-server`:

```bash
INTERFACESv4="enp0s8"   # interface da rede interna (ajustar conforme a máquina)
```

### Validação e inicialização

```bash
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf      # checa a sintaxe
sudo systemctl restart isc-dhcp-server      # sobe o serviço
sudo systemctl enable isc-dhcp-server       # habilita no boot
```

Toda essa configuração está automatizada no script `servidor_dhcp.sh`
(entregue junto). Os arquivos relevantes em operação são:

- `/etc/dhcp/dhcpd.conf` — configuração do servidor;
- `/var/lib/dhcp/dhcpd.leases` — concessões (leases) já ofertadas.

---

## 1.3 Testes e resultados

Os testes foram feitos em um ambiente isolado com *network namespaces* do Linux
(uma rede virtual servidor + cliente), de modo a não interferir na rede física.
A mesma configuração acima foi carregada no servidor e uma estação cliente
solicitou um endereço.

**Resultado — cliente obteve endereço dentro da faixa configurada:**

```
udhcpc: broadcasting discover
udhcpc: broadcasting select for 192.168.10.100, server 192.168.10.4
udhcpc: lease of 192.168.10.100 obtained from 192.168.10.4, lease time 600

inet 192.168.10.100/24 scope global veth-cli
```

**Lease registrado pelo servidor (`/var/lib/dhcp/dhcpd.leases`):**

```
lease 192.168.10.100 {
  starts 0 2026/06/21 21:32:48;
  ends 0 2026/06/21 21:42:48;
  binding state active;
  hardware ethernet f2:c1:e5:e3:c8:76;
}
```

O cliente recebeu o IP `192.168.10.100`, o gateway `192.168.10.254` e o DNS
`192.168.10.2`, exatamente como definido — confirmando o funcionamento do
serviço.

---

## 1.4 Respostas às questões do roteiro

### Questão 1 — Diálogos entre cliente e servidor (analisador de tráfego)

Capturando o tráfego nas portas UDP 67 (servidor) e 68 (cliente), observa-se a
sequência clássica do DHCP, conhecida como **DORA**. Saída registrada pelo
servidor durante o teste:

```
DHCPDISCOVER from f2:c1:e5:e3:c8:76 via veth-srv
DHCPOFFER on 192.168.10.100 to f2:c1:e5:e3:c8:76 via veth-srv
DHCPREQUEST for 192.168.10.100 (192.168.10.4) from f2:c1:e5:e3:c8:76 via veth-srv
DHCPACK on 192.168.10.100 to f2:c1:e5:e3:c8:76 via veth-srv
```

Explicação de cada mensagem:

1. **DHCP Discover** — o cliente, ainda sem IP, envia um *broadcast*
   (`0.0.0.0` → `255.255.255.255`) procurando servidores DHCP na rede.
2. **DHCP Offer** — o servidor responde oferecendo um endereço livre da faixa,
   junto com máscara, gateway, DNS e tempo de concessão (lease).
3. **DHCP Request** — o cliente, também em *broadcast*, anuncia que aceita
   aquela oferta (e avisa os demais servidores que escolheu este).
4. **DHCP Ack** — o servidor confirma a concessão e grava o lease.

Mensagens complementares do protocolo: a **renovação** do lease usa apenas
Request/Ack em *unicast*; ao liberar o endereço (`dhclient -r`), o cliente envia
um **DHCP Release**; e, quando o servidor recusa um pedido incoerente, envia um
**DHCP Nak**.

### Questão 2 — Ofertar IP apenas a estações com MAC previamente reconhecido

A alteração consiste em (a) adicionar `deny unknown-clients;` dentro da sub-rede
— assim **só** clientes com declaração `host` recebem endereço — e (b) declarar
cada estação autorizada por seu MAC:

```conf
subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.100 192.168.10.200;
    deny unknown-clients;          # só atende MACs declarados
    option routers 192.168.10.254;
}

host estacao-conhecida {
    hardware ethernet 02:00:00:00:00:11;
    fixed-address 192.168.10.50;
}
```

**Teste realizado** — o mesmo cliente solicitou IP duas vezes, primeiro com o
MAC cadastrado e depois com um MAC desconhecido:

```
>>> Cliente com MAC CADASTRADO: 02:00:00:00:00:11
udhcpc: lease of 192.168.10.50 obtained from 192.168.10.4, lease time 600
RESULTADO: recebeu IP -> inet 192.168.10.50

>>> Cliente com MAC DESCONHECIDO: 02:00:00:00:00:99
udhcpc: broadcasting discover
udhcpc: broadcasting discover
udhcpc: broadcasting discover
udhcpc: no lease, failing
RESULTADO: NENHUM IP recebido (servidor recusou - MAC não cadastrado).
```

Log do servidor, confirmando que o MAC desconhecido foi rejeitado (Discover
sem Offer):

```
DHCPDISCOVER from 02:00:00:00:00:11 via veth-srv
DHCPOFFER on 192.168.10.50 to 02:00:00:00:00:11 via veth-srv
DHCPACK on 192.168.10.50 to 02:00:00:00:00:11 via veth-srv
DHCPDISCOVER from 02:00:00:00:00:99 via veth-srv: unknown client
DHCPDISCOVER from 02:00:00:00:00:99 via veth-srv: unknown client
DHCPDISCOVER from 02:00:00:00:00:99 via veth-srv: unknown client
```

**Conclusão:** apenas a estação com MAC cadastrado (`...:11`) recebeu o endereço
(`192.168.10.50`); o MAC não cadastrado (`...:99`) teve seus DISCOVERs marcados
como *unknown client* e ficou sem IP.

### Questão 3 — Mais de um servidor DHCP na mesma rede

Foram colocados **dois** servidores DHCP na mesma rede: o **Servidor A**
(`192.168.10.4`, legítimo — faixa `.100–.150`, gateway correto `.254`, DNS do
grupo `.2`) e o **Servidor B** (`192.168.10.5`, simulando um servidor não
autorizado / *rogue* — faixa `.160–.200`, gateway errado `.111`, DNS externo
`8.8.8.8`). O cliente solicitou endereço 5 vezes:

| Tentativa | Veio do servidor | IP | Gateway | DNS |
|---|---|---|---|---|
| 1 | **A (.4, correto)** | 192.168.10.100 | 192.168.10.254 | 192.168.10.2 |
| 2 | **B (.5, rogue)**   | 192.168.10.160 | 192.168.10.111 | 8.8.8.8 |
| 3 | **B (.5, rogue)**   | 192.168.10.160 | 192.168.10.111 | 8.8.8.8 |
| 4 | **B (.5, rogue)**   | 192.168.10.160 | 192.168.10.111 | 8.8.8.8 |
| 5 | **B (.5, rogue)**   | 192.168.10.160 | 192.168.10.111 | 8.8.8.8 |

Resultado: 1 concessão veio do servidor correto e 4 do servidor rogue.

**Conclusão:** quando há mais de um servidor DHCP na mesma rede, ambos respondem
ao mesmo Discover com Offers distintas, e **não há coordenação entre eles**. O
cliente simplesmente aceita a **primeira oferta que chegar**, o que torna o
resultado **não-determinístico** — a cada pedido ele pode pegar configurações de
um servidor diferente. No teste, na maioria das vezes o cliente acabou pegando o
gateway (`192.168.10.111`) e o DNS (`8.8.8.8`) **errados** do servidor rogue, o
que quebraria o acesso à rede e, no caso de um servidor malicioso, permitiria um
ataque *man-in-the-middle* (o atacante direciona o tráfego para um gateway/DNS
sob seu controle). Os riscos são: conflito de endereços, parâmetros de rede
inconsistentes e desvio de tráfego.

Por isso, em produção deve existir **um único** servidor DHCP autoritativo por
sub-rede (ou servidores coordenados em modo *failover*), e recomenda-se ativar
**DHCP Snooping** nos switches gerenciáveis, que bloqueia respostas DHCP vindas
de portas não confiáveis.
