import 'package:flutter/material.dart'; 

class KiseCardHolder extends StatelessWidget {
  final Widget child; 
  final Color? backgroundColor; 
  final EdgeInsetsGeometry? padding; 
  final double borderRadius; 
  final bool showShadow; 
  final Color? borderColor; 

  const KiseCardHolder({
    super.key, 
    required this.child, 
    this.backgroundColor, 
    this.padding, 
    this.borderRadius = 16.0, 
    this.showShadow = true, 
    this.borderColor, 
  }); 

  @override
  Widget build(BuildContext context){
    return Container(
      width: double.infinity, 
      padding: padding ?? const EdgeInsets.all(16.0), 
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor, //remember that cardColor has to be defined by abrish for it to work here
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow 
          ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4),
            ),
          ]
          : null, 
        border: Border.all(
          color: borderColor ?? Colors.black.withOpacity(0.1), 
          width: 1, 
        ), 
      ), 
      child: child, 
    ); 
  }
}