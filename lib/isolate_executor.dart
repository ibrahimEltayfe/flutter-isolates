import 'dart:developer';
import 'dart:isolate';

class IsolateExecutor{
  ReceivePort? receiver;
  ReceivePort? errorReceiver;
  Isolate? _isolate;
  Capability? _resumeCapability;

  Future<void> start(Future<void> Function(IsolateData data) entryPoint, dynamic data,{
    required Function(dynamic message) onData,
    required Function(dynamic message) onError
  }) async{
    if(_isolate != null){
      return;
    }

    receiver = ReceivePort();
    errorReceiver = ReceivePort();

    receiver?.listen(onData);

    errorReceiver?.listen((message) {
      if(message is List && message.length == 2){
        onError(RemoteError("Unhandled error",message[1].toString()));
      }else if(message != null){
        onError(message);
      }

      close();
    },);

    try{
      _isolate = await Isolate.spawn(
        _isolateClosure,
        _IsolateMessage(
          entryPoint: entryPoint,
          errorPort: errorReceiver!.sendPort,
          isolateData: IsolateData(
            sendPort: receiver!.sendPort,
            data: data
          ),
        ),
        onError: errorReceiver?.sendPort,
        onExit: errorReceiver?.sendPort,
        errorsAreFatal: true,
      );
    }catch(e, s){
      onError(RemoteError("error occurred while opening the isolate",s.toString()));
      close();
    }
  }

  void pause(){
    if (_isolate != null) {
      log('isolate Paused...');
      _resumeCapability = Capability();
      _isolate!.pause(_resumeCapability);
    }
  }

  void resume(){
    if (_isolate != null && _resumeCapability != null) {
      log('Resuming isolate...');
      _isolate!.resume(_resumeCapability!);
    }
  }

  void close(){
    _isolate?.kill();
    _isolate = null;

    receiver?.close();
    receiver = null;

    errorReceiver?.close();
    errorReceiver = null;

    _resumeCapability = null;
  }
}

void _isolateClosure(_IsolateMessage message,) async{
  try{
    await message.entryPoint(message.isolateData);
  }catch(e){
    Isolate.exit(message.errorPort, e);
  }
}

class _IsolateMessage{
  final Future<void> Function(IsolateData data) entryPoint;
  final SendPort errorPort;
  final IsolateData isolateData;


  _IsolateMessage({required this.entryPoint,required this.errorPort,required this.isolateData,} );
}

class IsolateData{
  final SendPort sendPort;
  final dynamic data;

  IsolateData({required this.sendPort, required this.data});
}