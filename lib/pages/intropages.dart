import 'package:ogs/pages/loginpage.dart';
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
              MyIntroPage(imgurl: 'im4'),
              MyIntroPage(
                imgurl: 'im2',
                titlecolor: Color.fromARGB(255, 233, 58, 116),
              ),
              MyIntroPage(imgurl: 'im1'),
              MyIntroPage(
                button: true,
                imgurl: 'im3',
                titlecolor: Color.fromARGB(255, 233, 58, 116),
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
      this.titlecolor = Colors.greenAccent,
      this.title = "Welcome",
      required this.imgurl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgcolor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('lib/assets/landing ui/$imgurl.jpg'),
          ),
          Column(
            children: [
              Text('Welcome',
                  style: GoogleFonts.aBeeZee(
                      color: titlecolor,
                      fontWeight: FontWeight.bold,
                      fontSize: 40)),
              Text(
                "This is a complete travel app",
                style: GoogleFonts.poppins(color: textcolor),
              )
            ],
          ),
          if (button)
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ));
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  color: const Color.fromARGB(255, 17, 23, 101),
                ),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.yellow),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.poppins(
                        color: const Color.fromARGB(255, 17, 23, 101),
                        fontSize: 23),
                  ),
                ),
              ),
            ),
          const SizedBox()
        ],
      ),
    );
  }
}
