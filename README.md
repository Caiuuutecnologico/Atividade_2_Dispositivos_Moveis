# Tempo por aqui

Aplicativo Flutter para consultar a previsão de cidades brasileiras pelo serviço XML do CPTEC/INPE.

## Funcionalidades

- Pesquisa de localidades por nome e seleção pelo identificador fornecido pelo CPTEC/INPE.
- Consulta da previsão de quatro dias, com data, temperaturas mínima e máxima, condição do tempo, ícone e índice UV quando enviado pelo serviço.
- Gráfico de linhas com temperaturas mínimas e máximas.
- Atualização manual e atualização por gesto de puxar para baixo.
- Estados de carregamento, mensagens para buscas sem resultado, respostas sem previsão e falhas de rede/serviço.
- Persistência da última cidade escolhida no armazenamento local do Android.
- Busca e previsão acessíveis na tela principal.

## Executar

É necessário ter Flutter e Android SDK instalados.

```sh
flutter pub get
flutter run
```

Para gerar o APK instalável:

```sh
flutter build apk --release
```

O arquivo será criado em `build/app/outputs/flutter-apk/app-release.apk`.

## Bibliotecas

- `http`: requisições HTTP para o serviço CPTEC/INPE.
- `xml`: leitura das respostas XML.
- `shared_preferences`: persistência local da cidade selecionada.
- Flutter Material: interface e gráfico desenhado com `CustomPainter`.

## Serviço e dados locais

A busca usa `listaCidades?city=...` e a previsão usa `cidade/{id}/previsao.xml`, conforme a [documentação dos Serviços Web do CPTEC/INPE](https://servicos.cptec.inpe.br/XML/). O identificador recebido na busca é mantido para consultar a previsão. O XML é interpretado campo a campo, aceitando campos opcionais ausentes. A aplicação salva apenas o identificador, nome e UF da última cidade escolhida; previsões são consultadas novamente ao abrir o app ou atualizar.


