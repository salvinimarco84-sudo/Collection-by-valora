import 'package:flutter/material.dart';
import '../auth/auth_copy.dart';
import '../auth/auth_repository.dart';
import '../../theme/valora_appearance.dart';

class HomePage extends StatelessWidget {
 const HomePage({super.key,required this.repository});
 final AuthRepository repository;
 @override Widget build(BuildContext context){
  final appearance=ValoraAppearance.instance; final preset=appearance.selected;
  return Scaffold(appBar:AppBar(title:Text(authText(context,'home')),actions:[
   IconButton(tooltip:appearanceText(context,'appearance'),onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AppearanceSettingsPage())),icon:const Icon(Icons.palette_outlined)),
   IconButton(tooltip:authText(context,'logout'),onPressed:repository.signOut,icon:const Icon(Icons.logout)),
  ]),
  body:Stack(fit:StackFit.expand,children:[
   CustomPaint(painter:ValoraThemeBackdropPainter(preset:preset)),
   Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Image.asset('valora_logo.png',width:360,height:360,fit:BoxFit.contain,semanticLabel:'COLLECTION by VALORA'))),
  ]));
 }
}
class AppearanceSettingsPage extends StatelessWidget {
 const AppearanceSettingsPage({super.key});
 @override Widget build(BuildContext context){
  final appearance=ValoraAppearance.instance;
  return Scaffold(appBar:AppBar(title:Text(appearanceText(context,'appearance'))),
   body:ListenableBuilder(listenable:appearance,builder:(context,_){
    return ListView(padding:const EdgeInsets.all(16),children:[
     Padding(padding:const EdgeInsets.only(bottom:14),child:Text(appearanceText(context,'choose'),style:Theme.of(context).textTheme.titleMedium)),
     GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:1.32,crossAxisSpacing:12,mainAxisSpacing:12),itemCount:ValoraAppearance.presets.length,itemBuilder:(context,index){
      final p=ValoraAppearance.presets[index];final selected=p.id==appearance.selectedThemeId;
      return InkWell(borderRadius:BorderRadius.circular(14),onTap:()=>appearance.setTheme(p.id),child:Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(14),border:Border.all(color:selected?p.accent:Theme.of(context).dividerColor,width:selected?3:1)),clipBehavior:Clip.antiAlias,child:Stack(fit:StackFit.expand,children:[
       CustomPaint(painter:ValoraThemeBackdropPainter(preset:p)),
       Align(alignment:Alignment.bottomCenter,child:Container(width:double.infinity,color:p.card.withValues(alpha:.92),padding:const EdgeInsets.symmetric(vertical:10,horizontal:8),child:Text(p.name,textAlign:TextAlign.center,style:TextStyle(color:p.text,fontWeight:FontWeight.w600)))),
       if(selected)Positioned(right:8,top:8,child:Icon(Icons.check_circle,color:p.accent)),
      ])));
     }),
    ]);
   }));
 }
}
