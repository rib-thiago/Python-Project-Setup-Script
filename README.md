# 🐍 Python Project Setup Script

Este repositório contém um script bash para automatizar a criação e configuração de novos projetos Python utilizando Poetry e Pyenv. O script pode ser executado tanto em modo interativo quanto com opções de linha de comando.

## 🚀 Funcionalidades

- Criação de um novo projeto Python com Poetry
- Definição da versão local do Python com Pyenv
- Configuração do arquivo `pyproject.toml` para utilizar a versão correta do Python
- Adição de dependências especificadas pelo usuário
- Ativação do ambiente virtual do Poetry

## 📦 Requisitos

- [Poetry](https://python-poetry.org/)
- [Pyenv](https://github.com/pyenv/pyenv)

## 💻 Uso

### Modo Interativo

Para executar o script em modo interativo, utilize a opção `-i`:

```bash
./script.sh -i
```

O script irá solicitar as seguintes informações:

- Nome do projeto
- Versão do Python (ex.: 3.10.13)
- Dependências separadas por espaço

### Modo Linha de Comando

Para executar o script com opções de linha de comando, utilize as opções `-n` para o nome do projeto, `-v` para a versão do python no projeto e `-d` para uma string entre aspas contendo as depedências separadas por espaço:

```bash
./script.sh -n <nome_do_projeto> -v <versão_python> -d "<dependência1> <dependência2> ..."
```

## 🔧 Tratamento de Erros

O script possui tratamento de erros para os seguintes casos:

- Verifica se o diretório do projeto já existe e solicita outro nome caso exista
- Verifica se a versão especificada do Python está instalada e, caso contrário, lista as versões instaladas
- Relata falhas na criação do projeto, na definição da versão do Python, na adição de dependências e na ativação do ambiente virtual

## 📜 Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---
👤 Feito por [Thiago Ribeiro](https://github.com/rib-thiago)