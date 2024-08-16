import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';

class TrackBusPage extends StatefulWidget {
  const TrackBusPage({super.key});

  @override
  State<TrackBusPage> createState() => _TrackBusPageState();
}

class _TrackBusPageState extends State<TrackBusPage> {

  double stepheight=130;
  int buspos=0;
  // @override
  // void initState() {
  //   stepheight=MediaQuery.of(context).size.height*.7/4;
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Center(
        child: Stack(
          children: [
            Container(
              width: 80,
              height: MediaQuery.of(context).size.height*.7,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                Container(
                  width: 8,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6)
                  ),
                ),
                Container(
                  width: 8,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6)
                  ),
                ),
                Container(
                  width: 8,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6)
                  ),
                ),
                Container(
                  width: 8,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6)
                  ),
                ),
                Container(
                  width: 8,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6)
                  ),
                ),
              ],),
            ),
            AnimatedPositioned(
              duration: Duration(seconds: 1),
              curve: Curves.easeIn,
              left: 10,
              right: 10,
              top: stepheight*buspos+20,
              child: Container(
                //width: 60,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50)
                ),
                child:const Icon(LineIcons.bus,size: 35,),
              ),
            )
          ],
        ),
      ))
    );
  }
}
