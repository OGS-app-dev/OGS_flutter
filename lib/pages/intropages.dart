import 'package:ogs/constants.dart';
import 'package:ogs/pages/student_or_staff_login.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPages extends StatefulWidget {
  const IntroPages({super.key});

  @override
  State<IntroPages> createState() => _IntroPagesState();
}

class _IntroPagesState extends State<IntroPages> {
  final PageController _controller = PageController();

  int pgno = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                pgno = index;
              });
            },
            children: const [
              MyIntroPage(imgurl: 'im1',title: "Get Yourself\n    Updated",),
              MyIntroPage(
                imgurl: 'im2',
                title: "Set Your\nLocation",
                titlecolor: pricol,
              ),
              MyIntroPage(imgurl: 'im3',
              title: "  Complete\n  Guide For\nYour Travel",),
              MyIntroPage(
                button: true,
                imgurl: 'im5',
                titlecolor: pricol,
              ),
            ],
          ),
          Container(
            alignment: const Alignment(0, 0.93),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                pgno == 0
                    ? TextButton(
                        onPressed: () {
                          _controller.jumpToPage(3);
                        },
                        child: const Text(
                          "skip",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 17, 23, 101),
                          ),
                        ))
                    : TextButton(
                        onPressed: () {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeIn,
                          );
                        },
                        child: const Text(
                          "back",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 17, 23, 101),
                          ),
                        )),
                SmoothPageIndicator(
                  effect: const ExpandingDotsEffect(
                      activeDotColor: Colors.yellow,
                      dotColor: Color.fromARGB(255, 13, 11, 134),
                      dotHeight: 10,
                      dotWidth: 10,
                      expansionFactor: 2),
                  controller: _controller,
                  count: 4,
                ),
                pgno != 3
                    ? TextButton(
                        onPressed: () {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeIn,
                          );
                        },
                        child: const Text(
                          "next",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 17, 23, 101),
                          ),
                        ))
                    : const Text("                   ")
              ],
            ),
          )
        ],
      ),
    );
  }
}

class MyIntroPage extends StatelessWidget {
  final Color? titlecolor;
  final Color? textcolor;
  final Color? bgcolor;
  final String title;
  final String imgurl;
  final bool button;

  const MyIntroPage(
      {super.key,
      this.button = false,
      this.bgcolor = Colors.white,
      this.textcolor = Colors.black,
      this.titlecolor = pricol,
      this.title = "Welcome",
      required this.imgurl});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxImageHeight = screenHeight * 0.5; // Restrict to 50% of screen height
    
    return Container(
      color: bgcolor,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 20),
            
            // Image container with restricted height
            Container(
              constraints: BoxConstraints(
                maxHeight: maxImageHeight,
                maxWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Image.asset(
                  'lib/assets/landing ui/$imgurl.png',
                  fit: BoxFit.contain, // Maintain aspect ratio while fitting within bounds
                  height: maxImageHeight,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title or Button section
            if (!button)
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: titlecolor,
                        fontWeight: FontWeight.bold,
                        fontSize: 35,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (button)
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentOrStaff(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: pricol,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: pricol,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 45, 
                            vertical: 12,
                          ),
                          child: Text(
                            'Get Started',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 23,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
    );
  }
}