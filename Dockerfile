
# PROBLEMA 1: Não usa multi-stage build
# Separa a instalação das dependências da imagem final
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# PROBLEMA 2: Usa uma tag :latest mutável
# Define uma versão específica do Python
FROM python:3.12-slim
WORKDIR /app

# PROBLEMA 3: Executa como ROOT por padrão
# Cria um usuário sem privilégios
RUN useradd --create-home nonroot

# Copia as dependências e os arquivos da aplicação
COPY --from=builder /root/.local /home/nonroot/.local
COPY --chown=nonroot:nonroot . /app

ENV PATH="/home/nonroot/.local/bin:$PATH"

# Permite gravar no diretório do banco de dados
RUN mkdir -p /app/instance && chown -R nonroot:nonroot /app/instance

USER nonroot

EXPOSE 8080

# PROBLEMA 4: Sem declaração de HEALTHCHECK
# Verifica se a API está respondendo
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health')" || exit 1

ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:8080", "app:create_app()"]