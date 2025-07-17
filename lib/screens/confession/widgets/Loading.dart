import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class Loading extends StatefulWidget {
  Loading({Key? key, this.height}) : super(key: key);
  double? height;

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Align(
          child: CircularProgressIndicator(
        color: Color(0xff2F65B9),
      )),
      width: double.infinity,
      height: widget.height ?? double.infinity,
    );
  }
}
