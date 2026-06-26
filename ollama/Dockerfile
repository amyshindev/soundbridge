FROM ollama/ollama:latest

RUN apt-get update && apt-get install -y curl

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 11434

ENTRYPOINT ["/bin/bash", "/start.sh"]