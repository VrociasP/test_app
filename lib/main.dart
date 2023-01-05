import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dttp_mqtt/dttp_mqtt.dart';

import 'package:ping_discover_network_v2/ping_discover_network_v2.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color _currentColor = Colors.pink;
  final _controller = CircleColorPickerController(
    initialColor: Colors.pink,
  );
  List<String> _devices = [];

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wiz Color',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _currentColor,
          title: Text('Wiz Color'),
          centerTitle: true,
        ),
        body: Center(
          child: CircleColorPicker(
            controller: _controller,
            onChanged: (color) {
              setState(() => _currentColor = color);
            },
            onEnded: (color) {
              final command =
                  '{"method":"setPilot","params":{"r":${color.red},"g":${color
                  .green},"b":${color
                  .blue}, "state":${true}, "dimming": ${10}}}';
              // final command =
              //     '{"method":"getPilot","params":{}}';
              print(command);
              discoverDevices(command);
            },
          ),
        ),
      ),
    );
  }

  Future<void> discoverDevices(String command) async {
    // List of IP addresses to try
    // List<String> addresses = ["192.168.1.150", "192.168.1.180", "192.168.1.190", "192.168.1.203"];

    Set<String> addresses = {};

    for (int i = 1; i <= 255; i++) {
      addresses.add('192.168.1.'+ i.toString());
    }

    // Port number to connect to
    int port = 38899;

    // Try to connect to each address
    for (String address in addresses) {
      try {
        // Connect to the device
        Socket socket = await Socket.connect(address, port, timeout: Duration(milliseconds: 100));

        // Connection was successful, device is reachable
        print('Connected to $address:$port');
        setState(() {
          _devices.add('$address');
        });

        // Close the socket
        socket.close();
      } catch (e) {
        // Connection failed, device is not reachable
        String error = '$e';
        print(error.contains("Connection refused"));
        if(error.contains("Connection refused")){
          setState(() {
            _devices.add('$address');
          });
        }
      }
    }
    print(_devices);
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 38899)
        .then((socket) {
      socket.broadcastEnabled = true;
      print(_devices);
      for(String i in _devices) {
        print(i);
        socket.send(utf8.encode(command),
            InternetAddress(i), 38899);
      }

      // socket.listen((event) async {
      //   print("listen");
      //   if (event == RawSocketEvent.read) {
      //     final datagram = socket.receive();
      //     final data = datagram?.data;
      //     final addr = datagram?.address;
      //     final port = datagram?.port;
      //     print('Received packet from $addr:$port: $data');
      //   }
      // });

      socket.close();
    });
  }
}
