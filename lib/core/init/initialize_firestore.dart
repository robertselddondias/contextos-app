// utils/word_relation_seeder.dart
import 'package:contextual/data/datasources/remote/firebase_context_service.dart';
import 'package:flutter/foundation.dart';

/// Classe utilitária para popular palavras e suas relações
class WordRelationSeeder {
  final FirebaseContextService _contextService = FirebaseContextService();

  /// Popula o banco de dados com palavras básicas para teste
  Future<bool> seedBasicWords() async {
    try {
      await _contextService.initialize();

      // Lista de palavras e suas relações
      final wordRelations = [
      {
        "word": "música",
    "relations": {
    "som": 0.95,
    "melodia": 0.95,
    "ritmo": 0.95,
    "canção": 0.9,
    "harmonia": 0.9,
    "instrumento": 0.9,
    "nota": 0.85,
    "compositor": 0.85,
    "orquestra": 0.85,
    "banda": 0.85,
    "concerto": 0.85,
    "artista": 0.8,
    "festival": 0.8,
    "disco": 0.8,
    "álbum": 0.8,
    "cultura": 0.75,
    "entretenimento": 0.75,
    "dança": 0.75,
    "rádio": 0.75,
    "acústica": 0.75
  }
  },
    {
    "word": "computador",
    "relations": {
    "máquina": 0.95,
    "tecnologia": 0.95,
    "processador": 0.95,
    "memória": 0.9,
    "hardware": 0.9,
    "software": 0.9,
    "teclado": 0.9,
    "mouse": 0.9,
    "monitor": 0.9,
    "programa": 0.85,
    "internet": 0.85,
    "sistema": 0.85,
    "digital": 0.85,
    "dados": 0.85,
    "arquivo": 0.8,
    "rede": 0.8,
    "informática": 0.8,
    "usuário": 0.8,
    "notebook": 0.8,
    "eletrônico": 0.8
    }
    },
    {
    "word": "oceano",
    "relations": {
    "mar": 0.95,
    "água": 0.95,
    "profundo": 0.9,
    "onda": 0.9,
    "marinha": 0.9,
    "peixe": 0.9,
    "costa": 0.85,
    "praia": 0.85,
    "sal": 0.85,
    "maré": 0.85,
    "navio": 0.85,
    "barco": 0.85,
    "mergulho": 0.8,
    "marítimo": 0.8,
    "corrente": 0.8,
    "tempestade": 0.8,
    "horizonte": 0.75,
    "azul": 0.75,
    "vasto": 0.75,
    "atlântico": 0.75
    }
    },
    {
    "word": "livro",
    "relations": {
    "leitura": 0.95,
    "página": 0.95,
    "texto": 0.95,
    "autor": 0.9,
    "história": 0.9,
    "biblioteca": 0.9,
    "literatura": 0.9,
    "romance": 0.85,
    "capa": 0.85,
    "editora": 0.85,
    "publicação": 0.85,
    "conhecimento": 0.8,
    "livraria": 0.8,
    "papel": 0.8,
    "capítulo": 0.8,
    "leitor": 0.8,
    "cultura": 0.75,
    "imaginação": 0.75,
    "personagem": 0.75,
    "impresso": 0.75
    }
    },
    {
    "word": "montanha",
    "relations": {
    "elevação": 0.95,
    "pico": 0.95,
    "serra": 0.95,
    "altitude": 0.9,
    "escalada": 0.9,
    "rocha": 0.9,
    "cume": 0.9,
    "íngreme": 0.85,
    "cordilheira": 0.85,
    "vale": 0.85,
    "trilha": 0.85,
    "natureza": 0.8,
    "terreno": 0.8,
    "paisagem": 0.8,
    "alpinismo": 0.8,
    "aventura": 0.75,
    "neve": 0.75,
    "vegetação": 0.75,
    "geografia": 0.75,
    "vulcão": 0.75
    }
    },
    {
    "word": "médico",
    "relations": {
    "saúde": 0.95,
    "doutor": 0.95,
    "hospital": 0.95,
    "clínica": 0.9,
    "paciente": 0.9,
    "tratamento": 0.9,
    "enfermidade": 0.9,
    "consulta": 0.9,
    "diagnóstico": 0.85,
    "cirurgia": 0.85,
    "medicina": 0.85,
    "especialista": 0.85,
    "exame": 0.85,
    "profissional": 0.8,
    "receita": 0.8,
    "ambulância": 0.8,
    "cuidado": 0.8,
    "doença": 0.8,
    "terapia": 0.75,
    "medicamento": 0.75
    }
    },
    {
    "word": "restaurante",
    "relations": {
    "comida": 0.95,
    "refeição": 0.95,
    "estabelecimento": 0.95,
    "chef": 0.9,
    "gastronomia": 0.9,
    "cardápio": 0.9,
    "garçom": 0.9,
    "cozinha": 0.9,
    "cliente": 0.85,
    "menu": 0.85,
    "jantar": 0.85,
    "almoço": 0.85,
    "sabor": 0.85,
    "prato": 0.85,
    "bebida": 0.8,
    "conta": 0.8,
    "serviço": 0.8,
    "gourmet": 0.8,
    "ambiente": 0.75,
    "reserva": 0.75
    }
    },
    {
    "word": "cinema",
    "relations": {
    "filme": 0.95,
    "tela": 0.95,
    "projeção": 0.95,
    "ator": 0.9,
    "diretor": 0.9,
    "sessão": 0.9,
    "ingresso": 0.9,
    "roteiro": 0.9,
    "estreia": 0.85,
    "cena": 0.85,
    "pipoca": 0.85,
    "sala": 0.85,
    "espectador": 0.85,
    "bilheteria": 0.8,
    "trailer": 0.8,
    "entretenimento": 0.8,
    "audiovisual": 0.8,
    "produção": 0.75,
    "arte": 0.75,
    "Hollywood": 0.75
    }
    },
    {
    "word": "futebol",
    "relations": {
    "esporte": 0.95,
    "bola": 0.95,
    "campo": 0.95,
    "jogador": 0.9,
    "time": 0.9,
    "gol": 0.9,
    "torcida": 0.9,
    "estádio": 0.9,
    "campeonato": 0.85,
    "técnico": 0.85,
    "jogo": 0.85,
    "juiz": 0.85,
    "partida": 0.85,
    "competição": 0.8,
    "atleta": 0.8,
    "chute": 0.8,
    "passe": 0.8,
    "uniforme": 0.75,
    "torcedor": 0.75,
    "Mundial": 0.75
    }
    },
    {
    "word": "floresta",
    "relations": {
    "árvore": 0.95,
    "vegetação": 0.95,
    "mata": 0.95,
    "verde": 0.9,
    "planta": 0.9,
    "ecossistema": 0.9,
    "selva": 0.9,
    "natureza": 0.9,
    "animal": 0.85,
    "madeira": 0.85,
    "bosque": 0.85,
    "bioma": 0.85,
    "folha": 0.85,
    "biodiversidade": 0.8,
    "raiz": 0.8,
    "preservação": 0.8,
    "sombra": 0.8,
    "oxigênio": 0.75,
    "umidade": 0.75,
    "ambiente": 0.75
    }
    },
    {
    "word": "relógio",
    "relations": {
    "tempo": 0.95,
    "hora": 0.95,
    "ponteiro": 0.95,
    "cronômetro": 0.9,
    "pulso": 0.9,
    "digital": 0.9,
    "analógico": 0.9,
    "minuto": 0.9,
    "segundo": 0.85,
    "alarme": 0.85,
    "pulseira": 0.85,
    "precisão": 0.85,
    "mostrador": 0.85,
    "acessório": 0.8,
    "corda": 0.8,
    "bateria": 0.8,
    "horário": 0.8,
    "medida": 0.75,
    "pontualidade": 0.75,
    "suíço": 0.75
    }
    },
    {
    "word": "café",
    "relations": {
    "bebida": 0.95,
    "cafeína": 0.95,
    "grão": 0.95,
    "xícara": 0.9,
    "quente": 0.9,
    "cafeteira": 0.9,
    "expresso": 0.9,
    "aroma": 0.9,
    "coado": 0.85,
    "moído": 0.85,
    "amargo": 0.85,
    "torrado": 0.85,
    "robusta": 0.85,
    "arabica": 0.85,
    "sabor": 0.8,
    "manhã": 0.8,
    "energético": 0.8,
    "cafeteria": 0.8,
    "plantação": 0.75,
    "colheita": 0.75
    }
    },
    {
    "word": "avião",
    "relations": {
    "aeronave": 0.95,
    "voo": 0.95,
    "transporte": 0.95,
    "piloto": 0.9,
    "altitude": 0.9,
    "aeroporto": 0.9,
    "passageiro": 0.9,
    "viagem": 0.9,
    "turbina": 0.85,
    "asa": 0.85,
    "decolagem": 0.85,
    "pouso": 0.85,
    "hangar": 0.85,
    "jato": 0.85,
    "cargueiro": 0.8,
    "aéreo": 0.8,
    "cabine": 0.8,
    "combustível": 0.8,
    "velocidade": 0.75,
    "altitude": 0.75
    }
    },
    {
    "word": "hospital",
    "relations": {
    "saúde": 0.95,
    "médico": 0.95,
    "paciente": 0.95,
    "internação": 0.9,
    "tratamento": 0.9,
    "clínica": 0.9,
    "enfermeiro": 0.9,
    "emergência": 0.9,
    "doença": 0.85,
    "medicamento": 0.85,
    "cuidado": 0.85,
    "leito": 0.85,
    "cirurgia": 0.85,
    "ambulância": 0.85,
    "atendimento": 0.8,
    "diagnóstico": 0.8,
    "consulta": 0.8,
    "pronto-socorro": 0.8,
    "exame": 0.75,
    "recuperação": 0.75
    }
    },
    {
    "word": "estrela",
    "relations": {
    "astro": 0.95,
    "céu": 0.95,
    "luz": 0.95,
    "brilho": 0.9,
    "noite": 0.9,
    "cosmos": 0.9,
    "galáxia": 0.9,
    "constelação": 0.9,
    "sol": 0.85,
    "universo": 0.85,
    "espaço": 0.85,
    "telescópio": 0.85,
    "astronômico": 0.85,
    "distante": 0.8,
    "planeta": 0.8,
    "luminoso": 0.8,
    "celeste": 0.8,
    "cintilante": 0.75,
    "infinito": 0.75,
    "astrologia": 0.75
    }
    },
    {
    "word": "mercado",
    "relations": {
    "comércio": 0.95,
    "venda": 0.95,
    "produto": 0.95,
    "compra": 0.9,
    "consumidor": 0.9,
    "loja": 0.9,
    "feira": 0.9,
    "negócio": 0.9,
    "preço": 0.85,
    "alimento": 0.85,
    "supermercado": 0.85,
    "economia": 0.85,
    "oferta": 0.85,
    "demanda": 0.85,
    "atacado": 0.8,
    "varejo": 0.8,
    "concorrência": 0.8,
    "comprador": 0.8,
    "distribuição": 0.75,
    "mercadoria": 0.75
    }
    },
    {
    "word": "chocolate",
    "relations": {
    "doce": 0.95,
    "cacau": 0.95,
    "sobremesa": 0.95,
    "bombom": 0.9,
    "confeitaria": 0.9,
    "barra": 0.9,
    "amargo": 0.9,
    "ao leite": 0.9,
    "cobertura": 0.85,
    "trufado": 0.85,
    "sabor": 0.85,
    "avelã": 0.85,
    "manteiga": 0.85,
    "meio-amargo": 0.85,
    "chocolate quente": 0.8,
    "confeiteiro": 0.8,
    "delícia": 0.8,
    "calórico": 0.8,
    "prazer": 0.75,
    "brigadeiro": 0.75
    }
    },
    {
    "word": "escola",
    "relations": {
    "educação": 0.95,
    "ensino": 0.95,
    "aluno": 0.95,
    "professor": 0.9,
    "aprendizagem": 0.9,
    "sala de aula": 0.9,
    "conhecimento": 0.9,
    "instituição": 0.9,
    "estudante": 0.85,
    "matéria": 0.85,
    "aula": 0.85,
    "diretor": 0.85,
    "colégio": 0.85,
    "estudo": 0.85,
    "lição": 0.8,
    "pedagógico": 0.8,
    "formação": 0.8,
    "disciplina": 0.8,
    "recreio": 0.75,
    "uniforme": 0.75
    }
    },
    {
    "word": "jardim",
    "relations": {
    "planta": 0.95,
    "flor": 0.95,
    "verde": 0.95,
    "natureza": 0.9,
    "canteiro": 0.9,
    "quintal": 0.9,
    "paisagismo": 0.9,
    "ornamental": 0.9,
    "arbusto": 0.85,
    "gramado": 0.85,
    "rosa": 0.85,
    "árvore": 0.85,
    "parque": 0.85,
    "horticultura": 0.85,
    "viveiro": 0.8,
    "vegetal": 0.8,
    "jardinagem": 0.8,
    "jardineiro": 0.8,
    "terraço": 0.75,
    "decorativo": 0.75
    }
    },
    {
    "word": "bicicleta",
    "relations": {
    "veículo": 0.95,
    "roda": 0.95,
    "pedal": 0.95,
    "ciclismo": 0.9,
    "ciclista": 0.9,
    "transporte": 0.9,
    "guidão": 0.9,
    "corrente": 0.9,
    "marcha": 0.85,
    "selim": 0.85,
    "freio": 0.85,
    "velocidade": 0.85,
    "pneu": 0.85,
    "locomoção": 0.85,
    "exercício": 0.8,
    "mountain bike": 0.8,
    "cicloviário": 0.8,
    "mecânica": 0.8,
    "equilíbrio": 0.75,
    "mobilidade": 0.75
    }
    },
    {
    "word": "celular",
    "relations": {
    "telefone": 0.95,
    "comunicação": 0.95,
    "smartphone": 0.95,
    "ligação": 0.9,
    "dispositivo": 0.9,
    "aplicativo": 0.9,
    "tela": 0.9,
    "touchscreen": 0.9,
    "mensagem": 0.85,
    "bateria": 0.85,
    "android": 0.85,
    "iPhone": 0.85,
    "móvel": 0.85,
    "carregador": 0.85,
    "internet": 0.8,
    "dados": 0.8,
    "portátil": 0.8,
    "operadora": 0.8,
    "tecnologia": 0.75,
    "câmera": 0.75
    }
    },
    {
    "word": "rio",
    "relations": {
    "água": 0.95,
    "corrente": 0.95,
    "curso": 0.95,
    "fluxo": 0.9,
    "nascente": 0.9,
    "foz": 0.9,
    "margem": 0.9,
    "leito": 0.9,
    "afluente": 0.85,
    "ponte": 0.85,
    "pesca": 0.85,
    "navegação": 0.85,
    "aquático": 0.85,
    "cachoeira": 0.85,
    "barco": 0.8,
    "corredeira": 0.8,
    "riacho": 0.8,
    "hidrografia": 0.8,
    "hidrelétrica": 0.75,
    "enxurrada": 0.75
    }
    },
    {
    "word": "fotografia",
    "relations": {
    "imagem": 0.95,
    "câmera": 0.95,
    "foto": 0.95,
    "retrato": 0.9,
    "lente": 0.9,
    "foco": 0.9,
    "flash": 0.9,
    "álbum": 0.9,
    "fotógrafo": 0.85,
    "registro": 0.85,
    "estúdio": 0.85,
    "enquadramento": 0.85,
    "digital": 0.85,
    "composição": 0.85,
    "exposição": 0.8,
    "ISO": 0.8,
    "tripé": 0.8,
    "zoom": 0.8,
    "artística": 0.75,
    "memória": 0.75
    }
    },
    {
    "word": "hotel",
    "relations": {
    "hospedagem": 0.95,
    "alojamento": 0.95,
    "quarto": 0.95,
    "hóspede": 0.9,
    "suíte": 0.9,
    "recepção": 0.9,
    "estadia": 0.9,
    "acomodação": 0.9,
    "turismo": 0.85,
    "viagem": 0.85,
    "reserva": 0.85,
    "diária": 0.85,
    "resort": 0.85,
    "check-in": 0.85,
    "pousada": 0.8,
    "turista": 0.8,
    "serviço": 0.8,
    "conforto": 0.8,
    "camareira": 0.75,
    "lobby": 0.75
    }
    },
    {
    "word": "piano",
    "relations": {
    "instrumento": 0.95,
    "música": 0.95,
    "tecla": 0.95,
    "pianista": 0.9,
    "som": 0.9,
    "concerto": 0.9,
    "melodia": 0.9,
    "erudito": 0.9,
    "acorde": 0.85,
    "clássico": 0.85,
    "cauda": 0.85,
    "teclado": 0.85,
    "partitura": 0.85,
    "conservatório": 0.85,
    "musical": 0.8,
    "afinação": 0.8,
    "harmonia": 0.8,
    "pedal": 0.8,
    "orquestra": 0.75,
    "recital": 0.75
    }
    },
    {
    "word": "igreja",
    "relations": {
    "religião": 0.95,
    "templo": 0.95,
    "deus": 0.95,
    "fé": 0.9,
    "catedral": 0.9,
    "padre": 0.9,
    "missa": 0.9,
    "culto": 0.9,
    "oração": 0.85,
    "sino": 0.85,
    "sacerdote": 0.85,
    "altar": 0.85,
    "cristão": 0.85,
    "católica": 0.85,
    "evangélica": 0.8,
    "santuário": 0.8,
    "sagrado": 0.8,
    "comunidade": 0.8,
    "paróquia": 0.75,
    "devoto": 0.75
    }
    },
    {
    "word": "chuva",
    "relations": {
    "água": 0.95,
    "tempo": 0.95,
    "precipitação": 0.95,
    "tempestade": 0.9,
    "clima": 0.9,
    "guarda-chuva": 0.9,
    "gota": 0.9,
    "temporal": 0.9,
    "nuvem": 0.85,
    "vento": 0.85,
    "trovão": 0.85,
    "meteorologia": 0.85,
    "umidade": 0.85,
    "enchente": 0.85,
    "molhado": 0.8,
    "céu": 0.8,
    "garoa": 0.8,
    "inverno": 0.8,
    "lama": 0.75,
    "poça": 0.75
    }
    },
    {
    "word": "elefante",
    "relations": {
    "animal": 0.95,
    "mamífero": 0.95,
    "tromba": 0.95,
    "grande": 0.9,
    "marfim": 0.9,
    "savana": 0.9,
    "manada": 0.9,
    "orelha": 0.9,
    "presa": 0.85,
    "pesado": 0.85,
    "cinza": 0.85,
    "selvagem": 0.85,
    "safári": 0.85,
    "África": 0.85,
    "zoológico": 0.8,
    "extinção": 0.8,
    "memória": 0.8,
    "inteligente": 0.8,
    "circo": 0.75,
    "lento": 0.75
    }
    },
    {
    "word": "trem",
    "relations": {
    "ferroviário": 0.95,
    "transporte": 0.95,
    "trilho": 0.95,
    "vagão": 0.9,
    "locomotiva": 0.9,
    "estação": 0.9,
    "viagem": 0.9,
    "passageiro": 0.9,
    "metrô": 0.85,
    "plataforma": 0.85,
    "bilhete": 0.85,
    "ferrovia": 0.85,
    "cargueiro": 0.85,
    "rápido": 0.85,
    "maquinista": 0.8,
    "dorminhoco": 0.8,
    "linha": 0.8,
    "composição": 0.8,
    "passagem": 0.75,
    "conexão": 0.75
    }
    },
    {
    "word": "pizza",
    "relations": {
    "comida": 0.95,
    "italiana": 0.95,
    "massa": 0.95,
    "queijo": 0.9,
    "forno": 0.9,
    "calabresa": 0.9,
    "tomate": 0.9,
    "redonda": 0.9,
    "fatia": 0.85,
    "molho": 0.85,
    "mozarela": 0.85,
    "restaurante": 0.85,
    "pizzaria": 0.85,
    "pizza margherita": 0.85,
    "refeição": 0.8,
    "sabor": 0.8,
    "rodízio": 0.8,
    "delivery": 0.8,
    "fast food": 0.75,
    "napolitana": 0.75
    }
    },
    {
    "word": "banana",
    "relations": {
    "fruta": 0.95,
    "amarela": 0.95,
    "tropical": 0.95,
    "cacho": 0.9,
    "madura": 0.9,
    "casca": 0.9,
    "doce": 0.9,
    "potássio": 0.9,
    "prata": 0.85,
    "nanica": 0.85,
    "bananeira": 0.85,
    "verde": 0.85,
    "alimento": 0.85,
    "carboidrato": 0.85,
    "vitamina": 0.8,
    "plantação": 0.8,
    "maca": 0.8,
    "energia": 0.8,
    "banana-split": 0.75,
    "smoothie": 0.75
    }
    },
    {
    "word": "advogado",
    "relations": {
    "direito": 0.95,
    "jurídico": 0.95,
    "leis": 0.95,
    "defesa": 0.9,
    "processo": 0.9,
    "tribunal": 0.9,
    "cliente": 0.9,
    "justiça": 0.9,
    "juiz": 0.85,
    "fórum": 0.85,
    "OAB": 0.85,
    "julgamento": 0.85,
    "causa": 0.85,
    "advocacia": 0.85,
    "escritório": 0.8,
    "procuração": 0.8,
    "representação": 0.8,
    "profissional": 0.8,
    "petição": 0.75,
    "honorário": 0.75
    }
    },
    {
    "word": "diamante",
    "relations": {
    "joia": 0.95,
    "pedra": 0.95,
    "precioso": 0.95,
    "brilhante": 0.9,
    "carbono": 0.9,
    "lapidação": 0.9,
    "quilate": 0.9,
    "gema": 0.9,
    "anel": 0.85,
    "mina": 0.85}}];

      // Salva cada palavra e suas relações
      for (final item in wordRelations) {
        final word = item['word'] as String;
        final relations = Map<String, double>.from(item['relations'] as Map);

        final success = await _contextService.saveWordRelations(word, relations);

        if (!success) {
          if (kDebugMode) {
            print('Erro ao salvar relações para "$word"');
          }
        }
      }

      if (kDebugMode) {
        print('Palavras básicas populadas com sucesso!');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao popular palavras básicas: $e');
      }
      return false;
    }
  }

  /// Testa a similaridade entre duas palavras
  Future<double> testSimilarity(String word1, String word2) async {
    await _contextService.initialize();
    return _contextService.calculateSimilarity(word1, word2);
  }
}
