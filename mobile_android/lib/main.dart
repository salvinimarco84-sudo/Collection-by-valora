import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';
import 'src/theme/valora_appearance.dart';

const _supabaseUrl=String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey=String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await ValoraAppearance.instance.load();
 if(_supabaseUrl.isEmpty||_supabasePublishableKey.isEmpty){runApp(const ValoraApp(configurationError:true));return;}
 await Supabase.initialize(url:_supabaseUrl,publishableKey:_supabasePublishableKey);
 runApp(const ValoraApp());
}
