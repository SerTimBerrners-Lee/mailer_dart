import 'dart:convert';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> main() async {
  final server = await createServer();
  print('Server started: ${server.address} port ${server.port}');
  await _handleRequests(server);
}

Future<HttpServer> createServer() async {
  final address = InternetAddress.loopbackIPv4;
  const port = 4040;
  return await HttpServer.bind(address, port);
}

Future<void> _handleRequests(HttpServer server) async {
  await for (HttpRequest request in server) {
    if (request.method == 'POST' && request.uri.path == '/contact') {
      print('+ new request');
      _handleContactPost(request);
    } else {
      _handleBadRequest(request);
    }
  }
}

void _handleBadRequest(HttpRequest request) {
  request.response
    ..statusCode = HttpStatus.badRequest
    ..write('Bad request')
    ..close();
}

Future<void> _handleContactPost(HttpRequest request) async {
  final List<String> user_name = request.uri.queryParametersAll['user_name']!;
  final List<String> user_email = request.uri.queryParametersAll['user_email']!;
  final List<String> user_phone = request.uri.queryParametersAll['user_phone']!;

  final username = 'ask@ruterminal.ru';
  final password = 'rkgqkoakfqjnrvfs';

  final smtpServer = yandex(username, password);

  final message = Message()
    ..from = Address(username, 'RuTerminal')
    ..recipients.add('ask@ruterminal.ru')
    ..subject = 'Новая Заявка с Сайта'
    ..html = '''
        <p>Имя: <strong>${user_name[0]}</strong></p> 
        <p>Почта: <strong>${user_email[0]}</strong></p>
        <p>Телефон: <strong>${user_phone[0]}</strong></p>
      ''';

  final messageFromuser = Message()
    ..from = Address(username, 'RuTerminal')
    ..recipients.add(user_email[0])
    ..subject = 'RuTerminal'
    ..html = '''
      <h1>Приветствуем вас ${user_name[0]} </h1>
      <p>Мы получили вышу заявку. В ближайщее время наш менеджер с вами свяжется.</p>''';

  int statusCode;
  try {
    await send(message, smtpServer);
    final sendReport = await send(messageFromuser, smtpServer);

    print(sendReport.toString());
    statusCode = HttpStatus.ok;
  } on MailerException catch (e) {
    print('Message not sent: $e');
    statusCode = HttpStatus.internalServerError;
  }

  request.response
    ..statusCode = statusCode
    ..write('Successfully')
    ..close();
}
