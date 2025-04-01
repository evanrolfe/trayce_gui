import 'gen/api.pb.dart';

abstract class CommandSender {
  void sendCommandToAll(Command command);
}
