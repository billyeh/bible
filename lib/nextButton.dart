import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class NextButton extends StatelessWidget {
  const NextButton({
    Key key,
    this.next: '',
    this.text: 'Next',
  }) : super(key: key);

  final String next;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('MyButton was tapped!');
        if (this.next == '/') {
          Navigator.popUntil(context, ModalRoute.withName('/'));
        } else {
          Navigator.of(context).pushNamed(this.next);
        }
      },
      child: Container(
        height: 50.0,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
        child: Center(
          child: Text(
            this.text,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
