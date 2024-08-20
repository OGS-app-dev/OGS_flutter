import 'package:flutter/material.dart';
import '../Networking/gps_location.dart';
import '../form_response/form_response.dart';
import 'gmapscreen.dart';
import 'package:provider/provider.dart';

class LoadingScreen extends StatefulWidget {
  static const String id = "LoadingScreen";

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  GpsLocation gpsLocation = GpsLocation();

  void getLocationData() async {
    //get currentuser and its location only once
    //to not notice gap when getting location
    // await gpsLocation.getCurrentUser();
    await Provider.of<FormResponse>(context, listen: false)
        .initializeSharedPref();
    await gpsLocation.getFirstLocation();
    Provider.of<FormResponse>(context, listen: false)
        .addCurrentUserPosition(gpsLocation.currentPosition!);
    if (context.mounted) {
      await Provider.of<FormResponse>(context, listen: false).getIcon();
    }
    if (context.mounted) {
      Provider.of<FormResponse>(context, listen: false).createOriginalSet();
    }
    Provider.of<FormResponse>(context, listen: false).gpsLocation = gpsLocation;
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => GpsScreen(
                  gpsLocation: gpsLocation,
                )),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getLocationData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SpinKitWaveSpinner(
            //   color: Colors.blue[700]!,
            //   waveColor: Colors.blue,
            // ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Fetching Data..Please be patient",
            ),
          ],
        ),
      ),
    );
  }
}
