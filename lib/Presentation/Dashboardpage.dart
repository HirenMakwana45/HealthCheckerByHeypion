import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:healthcheckerbyheypion/Widgets/DbHelper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devices = [];
  DBHelper dbHelper = DBHelper();
  bool isScanning = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  //Function
  _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      print("Service UUID: ${service.uuid}");

      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        if (c.uuid.toString() == "YOUR_CHARACTERISTIC_UUID") {
          List<int> value = await c.read();
          var readings = value.toString().split(',');
          var db = await dbHelper.initDB();
          await dbHelper.insertData(db, {
            'systolic': int.parse(readings[0]),
            'diastolic': int.parse(readings[1]),
            'pulse': int.parse(readings[2]),
          });
        }
      }
    }
  }

  // _startScan() {
  //   setState(() {
  //     print("hey");
  //     isScanning = true;
  //   });
  //   flutterBlue.startScan(timeout: Duration(seconds: 5)).then((_) {
  //     setState(() {
  //       isScanning = false;
  //     });
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Let's Check Your Health !"),
      ),
      body: isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    strokeWidth: 5.0,
                  ),
                  SizedBox(height: 20),
                  Text('Searching for devices...',
                      style: TextStyle(fontSize: 16))
                ],
              ),
            )
          : StreamBuilder<List<ScanResult>>(
              stream: flutterBlue.scanResults,
              initialData: [],
              builder: (c, snapshot) {
                devices.clear();

                for (ScanResult r in snapshot.data!) {
                  devices.add(r.device);
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (_, index) {
                    return ListTile(
                      title: Text(devices[index].name),
                      onTap: () async {
                        await devices[index].connect().then((_) {
                          devices[index].state.listen((state) {
                            if (state == BluetoothDeviceState.connected) {
                              _discoverServices(devices[index]);
                            }
                          });
                        });
                        devices[index].connect();
                        _discoverServices(devices[index]);
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            log("Tapped");
            flutterBlue.startScan(timeout: Duration(seconds: 5)).then((_) {
              setState(() {
                isScanning = false;
              });
            });
          });
        },
        child: Icon(Icons.search),
      ),
    );
  }
}
