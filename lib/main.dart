import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<NotificationEvent> _log = [];
  bool started = false;
  String _message = "";
  bool _loading = false;

  ReceivePort port = ReceivePort();

  @override
  void initState() {
    // startListening();
    initPlatformState();
    startListeningNotification();
    super.initState();
  }

  @pragma(
      'vm:entry-point') // prevent dart from stripping out this function on release build in Flutter 3.x
  static void _callback(NotificationEvent evt) {
    print("send evt to ui: $evt");
    final SendPort? send = IsolateNameServer.lookupPortByName("_listener_");
    if (send == null) print("can't find the sender");
    send?.send(evt);
  }

  Future<void> initPlatformState() async {
    NotificationsListener.initialize(callbackHandle: _callback);
    IsolateNameServer.removePortNameMapping("_listener_");
    IsolateNameServer.registerPortWithName(port.sendPort, "_listener_");
    port.listen((message) => onData(message));
    var isRunning = (await NotificationsListener.isRunning) ?? false;
    print("""Service is ${!isRunning ? "not " : ""}already running""");

    setState(() {
      started = isRunning;
    });
  }

  void onData(NotificationEvent event) {
    setState(() {
      _log.add(event);
      _message = event.toString() ?? "Error reading message body.";

      // Ici on applique la logique pour le transfere des donnees vers notre serveur.


      // if (event.title == "OrangeMoney" &&
      //     event.text!.contains("Votre paiement de") &&
      //     event.text!.contains("FCFA a JOSHUA VISION JOSHUA VISION a ete effectue avec succes. Votre solde est de")) {
      //   RegExp montantRegex = RegExp(r"Votre paiement de (\d+\.?\d*) FCFA");
      //   Match? montantMatch = montantRegex.firstMatch(event.text!);
      //   String? montant = montantMatch != null ? montantMatch.group(1) : null;
      //   RegExp transIdRegex = RegExp(r"Trans id: (\w+\.\d+\.\d+)");
      //   Match? transIdMatch = transIdRegex.firstMatch(event.text!);
      //   String? transId = transIdMatch != null ? transIdMatch.group(1) : null;
      // }
    });

    print("##########################--NotificationEvent ${event.toString()} --##########################");
  }

  void startListeningNotification() async {
    // print("##########################-- start listening");
    setState(() {
      _loading = true;
    });
    var hasPermission = (await NotificationsListener.hasPermission) ?? false;
    if (!hasPermission) {
      // print("##########################-- no permission, so open settings");
      NotificationsListener.openPermissionSettings();
      return;
    }

    var isRunning = (await NotificationsListener.isRunning) ?? false;

    if (!isRunning) {
      await NotificationsListener.startService(
          foreground: true,
          title: "sms_project",
          description: "Start listening notifications");
    }

    setState(() {
      started = true;
      _loading = false;
    });
  }

  void stopListening() async {
    print("stop listening");

    setState(() {
      _loading = true;
    });

    await NotificationsListener.stopService();

    setState(() {
      started = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('Listening notifications app'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Center(child: Text("Latest received SMS: $_message")),
          Center(child: Text("Latest received SMS: $_message")),
          // TextButton(
          //     onPressed: () async {
          //       await telephony.openDialer("123413453");
          //     },
          //     child: Text('Open Dialer'))
        ],
      ),
    ));
  }
}
