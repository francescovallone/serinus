import 'package:meta/meta.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/models/models.dart';

class WsProvider extends SerinusProvider{

  late WebSocketContext _context;

  @nonVirtual
  @protected
  void initialize(WebSocketContext context){
    this._context = context;
  }

  Future<void> add<T>(T message) async {
    await _context.emit<T>(message);
  }

  void onMessage<T>(Function(T) callback) {
    _context.listen<T>(callback);
  }

  @protected
  Future<void> close() async{
    await _context.close();
  }
  
}