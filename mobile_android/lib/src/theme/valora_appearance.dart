import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ValoraThemePreset {
  const ValoraThemePreset(this.id,this.name,this.background,this.card,this.accent,this.text,this.light);
  final String id,name; final Color background,card,accent,text; final bool light;
}
String themeBackgroundAsset(String id) => switch (id) {
  'black_gold' => 'assets/themes/black_gold.jpg',
  'midnight_blue' => 'assets/themes/midnight_blue.jpg',
  'emerald' => 'assets/themes/electric_green.jpg',
  'silver_light' => 'assets/themes/silver_light.jpg',
  'dark_red' => 'assets/themes/fire_red.jpg',
  'royal_purple' => 'assets/themes/royal_purple.jpg',
  'comic' => 'assets/themes/comic_style.jpg',
  'minimal_zen' => 'assets/themes/minimal_zen.jpg',
  'industrial' => 'assets/themes/industrial.jpg',
  'pastel' => 'assets/themes/pastel.jpg',
  _ => 'assets/themes/black_gold.jpg',
};

class ValoraAppearance extends ChangeNotifier {
  ValoraAppearance._();
  static final instance=ValoraAppearance._();
  static const presets=<ValoraThemePreset>[
    ValoraThemePreset('black_gold','Black & Gold',Color(0xFF101010),Color(0xB81C1C1C),Color(0xFFD6B15E),Colors.white,false),
    ValoraThemePreset('midnight_blue','Midnight Blue',Color(0xFF071321),Color(0xB810243A),Color(0xFF20B8FF),Color(0xFFF4F8FF),false),
    ValoraThemePreset('emerald','Electric Green',Color(0xFF050A07),Color(0x98101912),Color(0xFF39FF62),Color(0xFFF1FFF4),false),
    ValoraThemePreset('silver_light','Silver Light',Color(0xFFF1F4F7),Color(0xBFFFFFFF),Color(0xFF2878C7),Color(0xFF172333),true),
    ValoraThemePreset('dark_red','Fire Red',Color(0xFF100605),Color(0x98210B08),Color(0xFFFF452E),Color(0xFFFFF5F2),false),
    ValoraThemePreset('royal_purple','Royal Purple',Color(0xFF160D20),Color(0xB828153A),Color(0xFFD44CFF),Color(0xFFFFF5FF),false),
    ValoraThemePreset('comic','Comic Style',Color(0xFFFFD928),Color(0xFFFFFBEB),Color(0xFFE51D2A),Color(0xFF101010),true),
    ValoraThemePreset('minimal_zen','Minimal Zen',Color(0xFFF3EBDD),Color(0xFFFFFCF5),Color(0xFFB93D32),Color(0xFF27251F),true),
    ValoraThemePreset('industrial','Industrial',Color(0xFF20262B),Color(0xFF303940),Color(0xFFB9C4CC),Color(0xFFF1F4F6),false),
    ValoraThemePreset('pastel','Pastel',Color(0xFFFFF0F5),Colors.white,Color(0xFF19B7C9),Color(0xFF293344),true),
  ];
  String selectedThemeId='black_gold';
  bool listMode=false;
  ValoraThemePreset get selected => presets.firstWhere((p)=>p.id==selectedThemeId,orElse:()=>presets.first);
  Future<void> load() async {
    final prefs=await SharedPreferences.getInstance();
    final id=prefs.getString('valora_selected_theme')??'black_gold';
    listMode=prefs.getBool('valora_menu_list_mode')??false;
    selectedThemeId=presets.any((p)=>p.id==id)?id:'black_gold';
    notifyListeners();
  }
  Future<void> toggleLayout() async {
    listMode=!listMode;
    final prefs=await SharedPreferences.getInstance();
    await prefs.setBool('valora_menu_list_mode',listMode);
    notifyListeners();
  }
  Future<void> setTheme(String id) async {
    if(!presets.any((p)=>p.id==id)) return;
    selectedThemeId=id;
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('valora_selected_theme',id);
    await prefs.setBool('valora_white_background',selected.light);
    notifyListeners();
  }
}
class ValoraThemeBackdropPainter extends CustomPainter {
  const ValoraThemeBackdropPainter({required this.preset});
  final ValoraThemePreset preset;
  @override
  void paint(Canvas canvas,Size size) {
    final rect=Offset.zero&size;
    canvas.drawRect(rect,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[preset.background,Color.lerp(preset.background,preset.accent,.09)!,preset.background]).createShader(rect));
    canvas.drawRect(rect,Paint()..shader=RadialGradient(colors:[preset.accent.withValues(alpha:.22),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(size.width*.08,size.height*.08),radius:size.longestSide*.85)));
    final line=Paint()..color=preset.accent.withValues(alpha:.19)..style=PaintingStyle.stroke..strokeWidth=1.1;
    final fill=Paint()..color=preset.accent.withValues(alpha:.12);
    switch(preset.id) {
      case 'emerald':
        for(int r=0;r<12;r++){final y=size.height*r/11;final path=Path()..moveTo(0,y);for(double x=0;x<size.width;x+=54){path.lineTo(x+27,y);path.lineTo(x+27,y+(r.isEven?13:-13));path.lineTo(x+54,y+(r.isEven?13:-13));}canvas.drawPath(path,line);}
        break;
      case 'dark_red':
        for(int i=0;i<34;i++){final x=(i*79.0)%size.width,y=(i*113.0)%size.height;final path=Path()..moveTo(x,y);for(int n=1;n<6;n++){path.lineTo(x+n*8+(i%3)*4,y+n*15);}canvas.drawPath(path,line);}
        break;
      case 'black_gold':
        for(int i=0;i<18;i++){final path=Path()..moveTo(i*size.width/17,0);for(double y=0;y<size.height;y+=35){path.lineTo((i*size.width/17+y*.31)%size.width,y);}canvas.drawPath(path,line);}
        break;
      case 'comic':
        for(double x=0;x<size.width;x+=13){for(double y=0;y<size.height;y+=13){canvas.drawCircle(Offset(x,y),1.5,fill);}}
        break;
      case 'industrial':
        for(double y=0;y<size.height;y+=7){canvas.drawLine(Offset(0,y),Offset(size.width,y),line);}
        break;
      case 'midnight_blue':
        for(int i=0;i<90;i++){final p=Offset((i*67.0)%size.width,(i*131.0)%size.height);canvas.drawCircle(p,(i%3+1).toDouble(),fill);}
        break;
      case 'royal_purple':
        for(int i=0;i<25;i++){final x=(i*73.0)%size.width,y=(i*97.0)%size.height;final path=Path()..moveTo(x,y-17)..lineTo(x+9,y)..lineTo(x,y+17)..lineTo(x-9,y)..close();canvas.drawPath(path,line);}
        break;
      case 'silver_light':
        for(int i=0;i<17;i++){final p=Path()..moveTo(0,i*55.0)..cubicTo(size.width*.25,i*55+25,size.width*.7,i*55-20,size.width,i*55+8);canvas.drawPath(p,line);}
        break;
      case 'minimal_zen':
        for(int i=0;i<12;i++){canvas.drawOval(Rect.fromCenter(center:Offset(size.width*.78,size.height*.18+i*19),width:size.width*.7+i*8,height:26+i*3),line);}
        break;
      case 'pastel':
        final rnd=math.Random(9);for(int i=0;i<18;i++){canvas.drawCircle(Offset(rnd.nextDouble()*size.width,rnd.nextDouble()*size.height),18+rnd.nextDouble()*45,fill);}
        break;
    }
  }
  @override bool shouldRepaint(covariant ValoraThemeBackdropPainter old)=>old.preset.id!=preset.id;
}
String appearanceText(BuildContext context,String key) {
 const words={
 'appearance':{'it':'Personalizza VALORA','en':'Customize VALORA','fr':'Personnaliser VALORA','de':'VALORA anpassen','es':'Personalizar VALORA','pt':'Personalizar VALORA','zh':'自定义 VALORA','ja':'VALORA をカスタマイズ'},
 'choose':{'it':'Scegli un tema','en':'Choose a theme','fr':'Choisir un thème','de':'Design auswählen','es':'Elige un tema','pt':'Escolha um tema','zh':'选择主题','ja':'テーマを選択'},
 'active':{'it':'Tema attivo','en':'Active theme','fr':'Thème actif','de':'Aktuelles Design','es':'Tema activo','pt':'Tema ativo','zh':'当前主题','ja':'現在のテーマ'},
 };
 final lang=Localizations.localeOf(context).languageCode;
 return words[key]?[lang]??words[key]?['it']??key;
}
