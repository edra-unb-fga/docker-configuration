Clone o repositório com:

```bash
git clone git@github.com:edra-unb-fga/docker-configuration.git
```

## 1. Build da Imagem

Primeiro, crie uma pasta para o armazenamento dos Volumes do Docker, caso não tenha ainda:

```bash
mkdir -p ~/Volumes
```

**Atenção:** Crie um novo arquivo na raiz do projeto chamado `.env` e copie as informações do `.env.example` nele, alterando o valor da variável `HOST_USER` para o usuário do seu SO host.

 A imagem é pesada, mas contém tudo o que precisamos referente a PX4, simuladores e ROS 2. O tempo de build estimado fica entre 1h30 e 2h.

##  Inicialização do Container (Suporte Híbrido GPU NVIDIA e CPU)

O projeto está estruturado para suportar máquinas com placas de vídeo NVIDIA e máquinas com apenas processador/gráficos integrados (Intel/AMD).

### Opção A: Script Automático (Recomendado)

O repositório conta com um script que detecta automaticamente se o sistema possui uma GPU NVIDIA funcional antes de subir o serviço:

1. Dê permissão de execução ao script:

```bash
chmod +x start.sh
```

2. Execute o script de inicialização:

```bash
./start.sh
```

### Opção B: Inicialização Manual via Docker Compose

Se preferir rodar diretamente via terminal, escolha o comando correspondente ao hardware do seu computador:

- Para computadores SEM GPU dedicada (Apenas CPU / Gráficos Integrados):

```bash
docker compose up -d ros-px4-humble
```

- Para computadores COM GPU NVIDIA dedicada:

```bash
docker compose -f docker-compose.yaml -f docker-compose.nvidia.yaml up -d ros-px4-humble
```

## 2. Permissão de Interface Gráfica (X11)

Rode o comando abaixo no seu terminal fora do container (na sua máquina host). Ele é necessário para permitir que a interface do Gazebo e janelas do OpenCV abram corretamente dentro do container:

```bash
xhost local:docker
```

## 3. Acessar o Container

Após subir o container, acesse o terminal interativo através do comando:

```bash
docker exec -it ros-px4-humble bash
```

**Dica:** Sempre que precisar de um novo terminal dentro do container, basta executar o mesmo comando em uma nova aba do terminal do seu computador.

## 4. Verificações de Funcionamento

Você pode verificar se o ROS 2 está ativo executando:

```bash
ros2
```

Se o comando retornar `command not found`, carregue o ambiente executando:

```bash
source /opt/ros/humble/setup.bash
```

### Teste do Simulador (Gazebo)

Verifique se a interface gráfica do simulador está abrindo normalmente rodando o comando dentro do container:

```bash
gz sim
```

## Passo a Passo para o Teste de Simulação

### No computador (Fora do Docker):

1. Clone o repositório na pasta onde você organiza seus projetos:

```bash
git clone git@github.com:edra-unb-fga/Workspace_Template.git
```

2. Libere a interface gráfica para o Docker:

```bash
xhost +local:root
```

### Terminal 1 (Dentro do Docker - PX4 + Gazebo):

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500_mono_cam_down
```

### Terminal 2 (Dentro do Docker - Ponte MicroXRCE):

```bash
source /opt/ros/humble/setup.bash
MicroXRCEAgent udp4 -p 8888
```

### Terminal 3 (Dentro ou Fora do Docker - Estação de Controle):

Abra o QGroundControl para estabelecer a conexão de telemetria com o PX4 e evitar erros de pré-voo (`No connection to the GCS`):

```bash
./QGroundControl.AppImage
```

(Caso esteja usando o aplicativo instalado no sistema, basta abri-lo pelo menu de programas).

### Terminal 4 (Dentro do Docker - Sua Missão ROS 2):

1. Navegue até a pasta onde o repositório do projeto foi clonado/mapeado:

```bash
cd /caminho/para/sua/pasta/Workspace_Template
```

(Exemplo: `cd ~/Workspace_Template` ou `cd /home/$USER/Workspace_Template`)

2. Compile o workspace, carregue o ambiente e execute a missão:

```bash
colcon build
source install/setup.bash
ros2 run missao_template main
```