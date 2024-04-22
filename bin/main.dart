import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:nyxx/nyxx.dart';

void main(List<String> arguments) async {
  final dictionary = jsonDecode(File('dictionary.json').readAsStringSync());

  final token = Platform.environment['UZO_TOKEN'];

  void serve() async {
    INyxxWebsocket? bot;
    try {
      bot = handleBot(dictionary, token);
    } catch (_) {}
  }

  serve();
}

INyxxWebsocket handleBot(dictionary, token) {
  final bot = NyxxFactory.createNyxxWebsocket(
      token, GatewayIntents.allUnprivileged + GatewayIntents.messageContent)
    ..registerPlugin(Logging()) //  Default logging plugin
    ..registerPlugin(
        CliIntegration()) // Cli integration for nyxx allows stopping application via SIGTERM and SIGKILl
    ..registerPlugin(
        IgnoreExceptions()); // Plugin that handles uncaught exceptions that may occur

  bot.connect();

  // Listen to ready event. Invoked when bot is connected to all shards. Note that cache can be empty or not incomplete.
  bot.eventsWs.onReady.listen((IReadyEvent e) {
    print("Ready!");
  });

  //Here are the words to trigger the bot in chat
  const triggers = ['узо'];

  //Listen to all incoming messages
  bot.eventsWs.onMessageReceived.listen((IMessageReceivedEvent e) async {
    if (tossD100()) {
      final phrase = generatePhrase(dictionary);
      final messageBuilder = MessageBuilder.content(phrase);

      Future.delayed(Duration(milliseconds: 1500),
          () => e.message.channel.sendMessage(messageBuilder));
    } else if (!e.message.author.bot) {
      if (e.message.referencedMessage?.message?.author.id == bot.self.id ||
          checkIfBotTriggered(e.message.content, triggers)) {
        final replyBuilder = ReplyBuilder.fromMessage(e.message);

        final phrase = generatePhrase(dictionary);
        final messageBuilder = MessageBuilder.content(phrase)
          ..replyBuilder = replyBuilder;

        //Logging
        print('Боту написали: ${e.message.content}\n');
        print('Бот ответил: $phrase \n\n');

        Future.delayed(Duration(milliseconds: 1500),
            () => e.message.channel.sendMessage(messageBuilder));
      }
    }
  });
  return bot;
}

bool tossD100() {
  return Random().nextInt(100) == 0;
}

bool checkIfBotTriggered(String message, List<String> triggers) {
  for (var t in triggers) {
    if (message.toLowerCase().contains(t.toLowerCase())) {
      return true;
    }
  }
  return false;
}

String generatePhrase(dynamic dictionary) {
  const maxLength = 20;
  String w = 'start';

  List<String> _phrase = [];

  while (w != 'end') {
    if (w != 'start') {
      _phrase.add(w);
    } else {
      _phrase.add(' ');
    }
    var p = Random().nextDouble();

    double s = 0;

    for (var _w in dictionary[w]!.keys) {
      s += dictionary[w]![_w]!;
      if (s > p) {
        w = _w;

        break;
      }
    }
    if (_phrase.length > maxLength) break;
  }
  return _phrase.reduce((out, w) {
    if (w != 'start' && w != 'end') {
      out += w + ' ';
    }
    return out
        .replaceAll(' ,', ',')
        .replaceAll(' .', '.')
        .replaceAll(' ?', '?')
        .replaceAll(' !', '!');
  });
}
