# Deploy Automático com GitHub Actions

Este guia explica como configurar o **GitHub Actions** para construir sua imagem do Chatwoot Whitelabel automaticamente e enviá-la para o Docker Hub, sem precisar instalar nada no seu computador.

## Pré-requisitos

1.  Uma conta no [Docker Hub](https://hub.docker.com/).
2.  Este projeto subido para um repositório no GitHub.

---

## Passo 1: Configurar Segredos no GitHub

Para que o GitHub possa enviar a imagem para o seu Docker Hub, precisamos dar permissão a ele de forma segura.

1.  Vá para o seu repositório no **GitHub**.
2.  Clique em **Settings** (Configurações) > **Secrets and variables** > **Actions**.
3.  Clique em **New repository secret**.
4.  Adicione as seguintes chaves:

    | Nome | Valor |
    | :--- | :--- |
    | `DOCKERHUB_USERNAME` | Seu nome de usuário do Docker Hub (ex: `nexateam`) |
    | `DOCKERHUB_TOKEN` | Sua senha do Docker Hub ou um Access Token (Recomendado) |

> **Dica:** Para criar um Access Token no Docker Hub: Vá em *Account Settings* > *Security* > *New Access Token*.

---

## Passo 2: Disparar o Build

O build vai rodar automaticamente sempre que você fizer um **Push** (enviar código) para a branch `main` alterando algo na pasta `whitelabel-build`.

### Disparo Manual (Recomendado para testar)

Você também pode rodar manualmente a qualquer momento:

1.  No GitHub, vá na aba **Actions**.
2.  Selecione o workflow **Build and Push Custom Chatwoot** na esquerda.
3.  Clique em **Run workflow**.
4.  (Opcional) Mude a versão se desejar.
5.  Clique no botão verde **Run workflow**.

Aguarde o processo terminar (leva cerca de 5-10 minutos). Quando ficar verde (✅), sua imagem estará pronta no Docker Hub!

---

## Passo 3: Atualizar no Portainer

Agora que a imagem foi atualizada no Docker Hub, basta atualizar seu Stack no Portainer.

1.  Acesse seu Portainer.
2.  Vá em **Stacks** > Sua Stack do Chatwoot.
3.  Clique em **Editor**.
4.  Certifique-se que a imagem está apontando para o seu repositório:
    ```yaml
    image: seu-usuario/chatwoot-custom:v3.15.0
    ```
5.  Clique em **Update the stack**.
6.  **Importante:** Marque a opção **"Re-pull image and redeploy"**. Isso força o Portainer a baixar a nova versão que o GitHub acabou de criar.

---

## Solução de Problemas

- **Erro de Login**: Verifique se `DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN` estão corretos nas Secrets.
- **Imagem não atualiza**: Lembre-se de marcar "Re-pull image" no Portainer.

