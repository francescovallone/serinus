import 'package:meta/meta.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/models/models.dart';

class WsProvider extends SerinusProvider{

  bool get isInitialized => _context != null;


  @nonVirtual
  @protected
  WebSocketContext? _context;

  @nonVirtual
  void initialize(WebSocketContext context){
    if(!isInitialized){
      this._context = context;
    }
  }

  @nonVirtual
  @protected
  Future<void> emit(dynamic message) async{
    if(isInitialized){
      await _context!.emit(message);
    }
  }

  @nonVirtual
  @protected
  Future<void> retrieve(Function(dynamic) callback) async {
    if(isInitialized){
      _context!.listen(callback);
    }
  }

  @nonVirtual
  @protected
  Future<void> close() async{
    if(isInitialized){
      await _context!.close();
    }
  }
  
}