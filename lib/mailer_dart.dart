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
    print('+ new request');
    request.response.headers.add("Access-Control-Allow-Origin", "*");
    request.response.headers.add("Access-Control-Allow-Headers", "*");
    request.response.headers
        .add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");

    print(request.method);
    print(request.uri.path);

    if (request.method == 'POST' && request.uri.path == '/contact') {
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

class ItemData {
  final String user_name;
  final String user_email;
  final String user_phone;

  ItemData({
    required this.user_name,
    required this.user_email,
    required this.user_phone,
  });

  @override
  String toString() =>
      '{Name: $user_name : Email: $user_email : Phone: $user_phone}';
}

Future<void> _handleContactPost(HttpRequest request) async {
  try {
    Future<String> content = utf8.decodeStream(request);
    final res = await content;
    final Map<String, dynamic> map = json.decode(res);
    final dynamic user_name = map['user_name'];
    final dynamic user_email = map['user_email'];
    final dynamic user_phone = map['user_phone'];

    print(user_name);
    print(user_email);
    print(user_phone);

    final username = 'ask@ruterminal.ru';
    final password = 'rkgqkoakfqjnrvfs';

    final smtpServer = yandex(username, password);

    final message = Message()
      ..from = Address(username, 'RuTerminal')
      ..recipients.add('ask@ruterminal.ru')
      ..subject = 'Новая Заявка с Сайта'
      ..html = '''
          <p>Имя: <strong>${user_name!}</strong></p> 
          <p>Почта: <strong>${user_email!}</strong></p>
          <p>Телефон: <strong>${user_phone!}</strong></p>
        ''';

    final messageFromuser = Message()
      ..from = Address(username, 'RuTerminal')
      ..recipients.add(user_email)
      ..subject = 'RuTerminal'
      ..html = '''
        <h1>Приветствуем вас ${user_name!} </h1>
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
  } catch (err) {
    print(err);
    return _handleBadRequest(request);
  }
}
