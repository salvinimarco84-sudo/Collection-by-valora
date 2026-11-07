part of '../main.dart';

extension _Pr05RuntimeProcedure on _EditPurchasePageState {
  double? _money(dynamic v){
    if(v==null)return null;
    var s=v.toString().trim().replaceAll('€','').replaceAll(' ','');
    if(s.contains(','))s=s.replaceAll('.','').replaceAll(',','.');
    return double.tryParse(s);
  }
  String _code(Map<String,dynamic> r)=>(r['codice_acquisto']??r['purchase_code']??r['id']??'').toString();
  String _name(Map<String,dynamic> r)=>(r['descrizione_acquisto']??r['descrizione']??r['description']??'Acquisto').toString();
  dynamic _totalValue(Map<String,dynamic> r)=>r['importo_totale']??r['totale']??r['prezzo_acquisto']??r['amount'];
  double get _allocated=>_items.fold<double>(0,(s,r)=>s+((_money(r['importo']??r['prezzo_acquisto']??r['valore'])??0)*(int.tryParse((r['quantita']??1).toString())??1)));
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  Map<String,dynamic> _unwrap(Map<String,dynamic> r){
    final v=r['result'];return v is Map?Map<String,dynamic>.from(v):r;
  }
  Future<void> _lock()async{
    final r=await _ValoraRuntimeApi.call('acquire_lock',{'session_id':_session});
    final v=r['result'];
    if(v is Map&&v['acquisito']==true){_locked=true;return;}
    throw Exception(v is Map?(v['messaggio']??'Blocco archivio non acquisito.').toString():'Blocco archivio non acquisito.');
  }
  Future<void> _unlock()async{
    if(!_locked)return;
    try{await _ValoraRuntimeApi.call('release_lock',{'session_id':_session});}finally{_locked=false;}
  }
  Future<void> _search()async{
    if(_query.text.trim().isEmpty){_msg('Inserisci codice o descrizione.');return;}
    setState(()=>_busy=true);
    try{
      final r=await _ValoraRuntimeApi.call('procedure',{'procedure':'PR-05','step':'search','session_id':_session,'payload':{'query':_query.text.trim(),'codice_acquisto':_query.text.trim()}});
      final data=_unwrap(r);
      final raw=data['acquisti']??data['risultati']??data['results']??data['rows'];
      if(raw is! List)throw Exception('Il runtime non ha restituito una lista di acquisti.');
      if(!mounted)return;
      setState((){_found=raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();_purchase=null;_items=[];_last=null;_status=_found.isEmpty?'Nessun acquisto trovato.':'Seleziona l’acquisto da modificare.';});
    }catch(e){if(mounted)setState(()=>_status='Ricerca non completata: $e');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _load(Map<String,dynamic> row)async{
    setState(()=>_busy=true);
    try{
      final code=_code(row);
      if(code.isEmpty)throw Exception('Codice acquisto stabile mancante.');
      final r=await _ValoraRuntimeApi.procedure('PR-05','load',{'codice_acquisto':code,'purchase_code':code},sessionId:_session);
      final p=r['acquisto'] is Map?Map<String,dynamic>.from(r['acquisto']):r;
      final raw=p['oggetti']??p['allocazioni']??p['dettagli']??p['items'];
      final date=DateTime.tryParse((p['data_acquisto']??p['data']??p['purchase_date']??'').toString());
      final amount=_money(_totalValue(p));
      if(raw is! List||raw.isEmpty)throw Exception('Dettagli oggetto non disponibili: modifica bloccata.');
      if(date==null||amount==null)throw Exception('Data o totale originario mancanti.');
      if(!mounted)return;
      setState((){_purchase=p;_date.text=date.toIso8601String().substring(0,10);_total.text=amount.toStringAsFixed(2);_description.text=_name(p);_items=raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();_last=null;_confirmed=false;_status='Scheda completa caricata. Codice acquisto e codici oggetto saranno conservati.';});
    }catch(e){if(mounted)setState(()=>_status='Scheda non caricata: $e');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  bool _valid(){
    if(_purchase==null||_code(_purchase!).isEmpty){_msg('Seleziona un acquisto con codice valido.');return false;}
    if(DateTime.tryParse(_date.text.trim())==null){_msg('Data non valida. Usa AAAA-MM-GG.');return false;}
    final total=_money(_total.text);
    if(total==null||total<=0){_msg('Il totale deve essere maggiore di zero.');return false;}
    if(_items.isEmpty||_items.any((r)=>_money(r['importo']??r['prezzo_acquisto']??r['valore'])==null)){_msg('Allocazioni non complete: salvataggio bloccato.');return false;}
    if((_allocated-total).abs()>0.009){_msg('Quadratura non valida: somma allocazioni diversa dal totale.');return false;}
    return true;
  }
  Map<String,dynamic> _payload({bool confirmed=false,bool finalConfirmation=false})=> {
    'codice_acquisto':_code(_purchase!), 'purchase_code':_code(_purchase!),
    'data_acquisto':_date.text.trim(),
    'importo_totale':_money(_total.text),
    'dati_confermati':confirmed,'conferma_finale':finalConfirmation,
    'mantieni_codici_oggetto':true,'non_eliminare_ricreare':true,
    'aggiorna_cassa':true,'registra_storico':true,'verifica_quadratura':true,
  };
  Future<void> _preview()async{
    if(!_valid())return;setState(()=>_busy=true);
    try{await _lock();final r=await _ValoraRuntimeApi.procedure('PR-05','preview',_payload(),sessionId:_session);if(mounted)setState((){_last=r;_status='Anteprima completata: controlla le differenze prima della review.';});}
    catch(e){if(mounted)setState(()=>_status='Anteprima non riuscita: $e');}
    finally{await _unlock();if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _save()async{
    if(!_confirmed||_last==null||!_valid()){_msg('Controlla i dati e conferma il riepilogo prima di salvare.');return;}
    setState(()=>_busy=true);
    try{
      await _lock();
      final r=await _ValoraRuntimeApi.procedure('PR-05','save',_payload(confirmed:true,finalConfirmation:true),sessionId:_session,requestId:_uuid.v4());
      final rawResults=r['risultati'];
      final results=rawResults is List?rawResults.whereType<Map>().map((v)=>Map<String,dynamic>.from(v)).toList():<Map<String,dynamic>>[];
      final saved=r['scrittura_eseguita']==true&&r['stato']=='SALVATO_E_VERIFICATO'&&results.length==1&&results.every((v){
        final sameCode=(v['codice_acquisto']??'').toString()==_code(_purchase!);
        final cash=_money(v['importo_cassa']);
        final allocation=_money(v['quadratura_oggetti']);
        return sameCode&&v['verifica_database']==true&&cash!=null&&allocation!=null&&
          (cash-(_money(_total.text)??0)).abs()<=0.009&&
          (allocation-(_money(_total.text)??0)).abs()<=0.009;
      });
      if(r['blocco_rilasciato_automaticamente']==true)_locked=false;
      if(!mounted)return;
      setState((){_last=r;_status=saved?'Modifica verificata: codice conservato, quadratura, cassa e database confermati dalla procedura.':'Modifica NON considerata conclusa: la procedura non ha restituito tutte le verifiche richieste.';});
      if(saved&&mounted){
        final again=await showDialog<bool>(context:context,barrierDismissible:false,builder:(ctx)=>AlertDialog(
          title:const Text('Modifica verificata'),content:const Text('Vuoi modificare un altro acquisto?'),
          actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('NO, TERMINA')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('SÌ, ALTRO ACQUISTO'))]));
        if(!mounted)return;
        if(again==true)setState((){_query.clear();_found=[];_purchase=null;_items=[];_last=null;_confirmed=false;_status='Cerca un altro acquisto.';});
        else Navigator.of(context).pop();
      }
    }catch(e){if(mounted)setState(()=>_status='Modifica non confermata: $e');}
    finally{await _unlock();if(mounted)setState(()=>_busy=false);}
  }
}
