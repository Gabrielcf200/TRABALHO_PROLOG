# Etapa 08 — Executável (.exe)

> **Concluída em 2026-11-19.** `dist\SuperViaIA\SuperViaIA.exe` gerado (cerca de 100 MB). Ele abriu e a barra lateral consultou o Prolog empacotado. Falta testar com a chave real do Gemini.

**Objetivo:** abrir o app com dois cliques, sem precisar do Python instalado.

**Depende de:** [etapa 07](07-interface.md).

## Como gerar

Na raiz do projeto:

```bash
powershell -ExecutionPolicy Bypass -File app\gerar_exe.ps1
```

O script instala o PyInstaller 6 e gera a pasta `dist\SuperViaIA\` (modo `--onedir --windowed`, sem janela de console). Nela ficam:

| Arquivo | O que é |
|---------|---------|
| `SuperViaIA.exe` | o app |
| `_internal\` | Python, bibliotecas e `src\*.pl` empacotados |
| `.env.example` | modelo da configuração |

## Para usar em outro PC

1. Copiar a pasta `dist\SuperViaIA\` inteira.
2. Ter o **SWI-Prolog instalado** na máquina. Ele não vai dentro do `.exe`.
3. Copiar `.env.example` para `.env`, **ao lado do `.exe`**, e colar a chave do Gemini. A chave nunca é empacotada dentro do executável. Se o `app\.env` existir, o script avisa e não copia.

## Como o código acha os arquivos no .exe

- `prolog.py`: os `.pl` ficam em `sys._MEIPASS/src`.
- `llm.py`: o `.env` fica em `Path(sys.executable).parent`.

## Fora desta etapa

Instalador (`setup.exe`), ícone próprio, assinatura digital e embutir o SWI-Prolog junto. O Windows SmartScreen pode avisar na primeira vez que o `.exe` abre, porque ele não é assinado.
