// lib/services/websocket_queue_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:smartcare_app/models/appointment.dart';

class WebSocketQueueService {
  late final WebSocketChannel _channel;

  WebSocketQueueService({required String patientId, required String doctorId}) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.10:8080'), // Use your backend server URL
    );
  }

  Stream<List<Appointment>> getAppointmentsStream(String doctorId) {
    return _channel.stream.transform(
      StreamTransformer<dynamic, List<Appointment>>.fromHandlers(
        handleData: (data, sink) {
          try {
            final Map<String, dynamic> decodedData = json.decode(data);
            final List<dynamic> appointmentsJson = decodedData['queue'];

            final List<Appointment> appointments = appointmentsJson
                .map((json) => Appointment(
              id: json['patientId'] ?? '',
              patientId: json['patientId'] ?? '',
              patientName: json['name'] ?? '',
              doctorId: doctorId, // Use the passed doctorId
              time: '', // The backend data doesn't provide this, so it's a placeholder
              status: json['status'] ?? '',
              queueNumber: json['queueNumber'] ?? 0,
            ))
                .toList();

            sink.add(appointments);
          } catch (e) {
            print('Error decoding data: $e');
            sink.addError(e);
          }
        },
      ),
    );
  }

  void dispose() {
    _channel.sink.close();
  }
}