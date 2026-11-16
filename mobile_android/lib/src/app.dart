import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/auth_copy.dart';
import 'features/auth/auth_gate.dart';
import 'theme/valora_appearance.dart';

class ValoraApp extends StatefulWidget {
 const ValoraApp({super.key,this.configurationError=false});
 final bool configurationError;
 @override State<ValoraApp> createState()=>_ValoraAppState();
}
class _ValoraAppState extends State<ValoraApp> {
 @override void initState(){super.initState();ValoraAppearance.instance.addListener(_refresh);}
 void _refresh(){if(mounted)setState((){});}
 @override void dispose(){ValoraAppearance.instance.removeListener(_refresh);super.dispose();}
 @override Widget build(BuildContext context){
  final p=ValoraAppearance.instance.selected;
  return MaterialApp(debugShowCheckedModeBanner:false,
   localizationsDelegates:const [GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],
   supportedLocales:authLocales,
   localeResolutionCallback:(locale,supported){if(locale==null)return const Locale('it');return supported.firstWhere((v)=>v.languageCode==locale.languageCode,orElse:()=>const Locale('it'));},
   theme:ThemeData(useMaterial3:true,brightness:p.light?Brightness.light:Brightness.dark,
    scaffoldBackgroundColor:p.background,
    colorScheme:p.light?ColorScheme.light(primary:p.accent,secondary:p.accent,surface:p.card,onSurface:p.text,onPrimary:Colors.white):ColorScheme.dark(primary:p.accent,secondary:p.accent,surface:p.card,onSurface:p.text)),
   home:widget.configurationError?_ConfigurationPage():const AuthGate());
 }
}
class _ConfigurationPage extends StatelessWidget {
 @override Widget build(BuildContext context)=>Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(authText(context,'config'),textAlign:TextAlign.center))));
}
