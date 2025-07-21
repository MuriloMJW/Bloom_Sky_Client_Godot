# Cliente do Jogo 2D Multiplayer em Godot

![Godot Engine](https://img.shields.io/badge/godot-4.2+-478cbf.svg)
![GDScript](https://img.shields.io/badge/gdscript-purple.svg)

Este repositório contém o código-fonte para o cliente de jogo 2D multiplayer online chamado Bloom Sky, desenvolvido com o **Godot Engine**. Ele é responsável por toda a interação do usuário, renderização gráfica e comunicação em tempo real com o **[servidor Python backend]([https://github.com/SEU-USUARIO/SEU-REPOSITORIO-SERVIDOR](https://github.com/MuriloMJW/Bloom_Sky_Server_Python))**.


<img width="1916" height="654" alt="bloom sky" src="https://github.com/user-attachments/assets/c12e5279-2316-4ada-89fe-fdea0fa9ff71" />


## Principais Funcionalidades
- **Arquitetura Servidor-Autoritativo:** O cliente atua como um terminal de renderização. Ele envia os inputs do jogador (intenção de movimento, tiro) para o servidor, mas toda a lógica crítica (cálculos de colisão, dano, estado) é processada no servidor. Isso previne trapaças e garante consistência.
- **Interpolação de Movimento:** Utiliza interpolação linear (`lerp`) para suavizar o movimento de jogadores remotos, exibindo uma movimentação fluida em vez de "saltos" a cada pacote recebido.
- **Protocolo Binário Otimizado:** Comunica-se através de um protocolo binário customizado (`MyBuffer.gd`), que é significativamente mais leve que formatos de texto, e utiliza **bitmasks** para atualizações de estado parciais, economizando banda.
- **Design Desacoplado com Sinais:** A lógica de rede (`Client.gd`) é isolada da lógica de cena. As cenas reagem a eventos de rede através de sinais, criando um código limpo e de fácil manutenção.
- **Fluxo de Autenticação Seguro:** Implementa um handshake de duas etapas que separa a autenticação da entrada no jogo, garantindo que o jogador só "spawne" no servidor quando a cena do jogo estiver 100% carregada e pronta no cliente.

## Arquitetura do Cliente
O projeto é organizado em três camadas principais para uma clara separação de responsabilidades.

### 1. Camada de Rede (`Client.gd` - Autoload)
Este singleton é o **cérebro da rede**. Suas responsabilidades são:
- Gerenciar o estado da conexão `WebSocketPeer`.
- Enviar e receber todos os pacotes.
- Usar `MyBuffer.gd` para codificar e decodificar os dados do protocolo binário.
- Emitir sinais de alto nível (ex: `auth_successful`, `player_updated`) para o resto do jogo. Ele não tem conhecimento sobre cenas ou nodes.

### 2. Camada de Orquestração (`Game.gd`)
Este script é o **maestro da cena principal**. Ele:
- Ouve os sinais emitidos pelo `Client.gd`.
- Traduz esses eventos em ações no mundo do jogo, como instanciar (`spawn_player`) ou remover jogadores.
- Atua como uma ponte, conectando os sinais de input de um `Player.gd` de volta para o `Client.gd`, que os enviará ao servidor.

### 3. Camada de Ator (`Player.gd`)
Cada `Player.tscn` é uma **unidade autônoma**. Ela:
- Mantém seu próprio estado (vida, time, posição autoritativa).
- Atualiza sua própria aparência visual através de `setters` quando seu estado muda.
- Captura o input do teclado/mouse (se for o jogador local) e emite sinais de "intenção" (ex: `move_pressed`).
- Realiza a interpolação de sua própria posição para se mover suavemente até a `authoritative_position` ditada pelo servidor.

## Fluxo de Conexão e Jogo
1.  **Etapa 1 (Autenticação):** Na `main_menu.gd`, o usuário insere suas credenciais. O `Client.gd` envia um pacote `REQUEST_AUTH`. Ao receber `AUTH_SUCCESS` do servidor, o `Client.gd` emite o sinal `auth_successful`, que é capturado pela cena do menu para iniciar a transição para a cena do jogo.
2.  **Etapa 2 (Admissão):** Quando a cena `Game.gd` está pronta (`_ready`), ela chama `Client._request_connect()`. O `Client` envia o pacote `REQUEST_CONNECT`. O servidor então "spawna" o jogador em seu mundo e envia de volta os dados de todos os jogadores, que são usados para popular a cena.

## Requisitos
- **Godot Engine** (versão 4.2 ou superior).
- Uma instância do **[servidor Python](https://github.com/MuriloMJW/Bloom_Sky_Server_Python)** deve estar em execução.

## Como Executar
1.  Certifique-se de que o servidor esteja em execução.
2.  Clone este repositório para a sua máquina local.
3.  Abra o Godot Engine e use o botão "Importar" para selecionar o arquivo `project.godot`.
4.  Dentro do editor, abra o script `scripts/Client.gd`.
5.  Modifique a variável `websocket_url` para apontar para o endereço IP e porta corretos do seu servidor (ex: `"ws://127.0.0.1:9913"`).
6.  Pressione **F5** ou clique no ícone "Executar Projeto".

## Estrutura do Projeto

```
res://
├── scenes/
│   ├── main_menu.tscn      # Cena da tela de login/menu.
│   ├── game.tscn           # Cena principal do jogo.
│   └── player.tscn         # Cena para a entidade do jogador.
│
├── scripts/
│   ├── Client.gd           # (Autoload) Singleton para gerenciar a rede.
│   ├── main_menu.gd        # Lógica da tela de login.
│   ├── game.gd             # Lógica da cena principal do jogo.
│   ├── player.gd           # Lógica do nó do jogador.
│   └── my_buffer.gd        # Classe para manipulação do protocolo binário.
│
├── resources/
│   └── (Recursos como SpriteFrames, etc.)
│
└── project.godot           # Arquivo principal do projeto Godot.

```
