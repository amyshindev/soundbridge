#!/bin/bash
export OLLAMA_HOST=0.0.0.0:11434
ollama serve &
sleep 15
ollama pull nomic-embed-text
ollama pull exaone3.5:2.4b
wait