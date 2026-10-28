import 'dart:async';

import 'package:efashion_flutter/components/authComponent/domain/usecases/get_user_access_token_usecase.dart';
import 'package:efashion_flutter/components/chatSupportComponent/domain/entities/chat_message.dart';
import 'package:efashion_flutter/components/chatSupportComponent/domain/usecases/close_socket_connection.dart';
import 'package:efashion_flutter/components/chatSupportComponent/domain/usecases/create_or_join_existing_chat_usecase.dart';
import 'package:efashion_flutter/components/chatSupportComponent/domain/usecases/get_chat_messages_usecase.dart';
import 'package:efashion_flutter/components/chatSupportComponent/domain/usecases/get_chat_stream_usecase.dart';
import 'package:efashion_flutter/components/chatSupportComponent/domain/usecases/send_message_usecase.dart';
import 'package:dio/dio.dart';
import 'package:efashion_flutter/shared/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';

part 'chat_support_state.dart';

@injectable
class ChatSupportCubit extends Cubit<ChatSupportState> {
  final GetUserAccessTokenUseCase _getUserAccessTokenUseCase;
  final CreateOrJoinChatUseCase _createOrJoinChatUseCase;
  final GetChatMessagesUseCase _getChatMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final GetChatStreamUseCase _getChatStreamUseCase;
  final CloseSocketConnectionUseCase _closeSocketConnectionUseCase;
  late String userAccessToken;
  late StreamSubscription<ChatMessage> streamSubscription;

  ChatSupportCubit(
    this._getUserAccessTokenUseCase,
    this._createOrJoinChatUseCase,
    this._getChatMessagesUseCase,
    this._sendMessageUseCase,
    this._getChatStreamUseCase,
    this._closeSocketConnectionUseCase,
  ) : super(const ChatSupportState());

  Future<void> createOrJoinChatEvent() async {
    emit(state.copyWith(chatState: CubitState.loading));
    final getAccessToken = await _getUserAccessTokenUseCase();
    userAccessToken = getAccessToken.getOrElse(() => '');
    final response =
        await _createOrJoinChatUseCase(userAccessToken: userAccessToken);
    response.fold(
      (failure) => emit(
        state.copyWith(
          chatState: CubitState.failure,
        ),
      ),
      (chatId) async {
        emit(
          state.copyWith(
            chatId: chatId,
            chatState: CubitState.success,
          ),
        );
        _startChatStreamSubscription();
        await _getChatMessages();
      },
    );
  }

  Future<void> _getChatMessages() async {
    final response = await _getChatMessagesUseCase(chatId: state.chatId);
    response.fold(
      (failure) => emit(
        state.copyWith(
          chatMessagesState: CubitState.failure,
          chatFailMessage: failure.message,
        ),
      ),
      (chatMessages) => emit(
        state.copyWith(
          chatMessagesState: CubitState.success,
          chatMessages: chatMessages.reversed.toList(),
        ),
      ),
    );
  }

  Future<void> sendMessage({required String message}) async {
    if (state.chatId.isNotEmpty) {
      final response = await _sendMessageUseCase(
        message: message,
        chatId: state.chatId,
      );
      response.fold(
        (failure) => emit(
          state.copyWith(
              sendMessageState: CubitState.failure,
              chatFailMessage: failure.message),
        ),
        (sentMessage) {
          emit(
            state.copyWith(
              sendMessageState: CubitState.success,
              chatMessages: [sentMessage, ...state.chatMessages],
            ),
          );
          _triggerSmartBotReply(message);
        },
      );
    }
  }

  void _triggerSmartBotReply(String userQuery) {
    Timer(const Duration(milliseconds: 600), () async {
      String reply = '';

      // Tích hợp trực tiếp Google Gemini 1.5 Flash AI
      final geminiKey = dotenv.env['GEMINI_API_KEY'] ??
          dotenv.env['GOOGLE_GEMINI_KEY'] ??
          '';

      if (geminiKey.isNotEmpty) {
        try {
          final dio = Dio();
          final response = await dio.post(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiKey',
            data: {
              "contents": [
                {
                  "parts": [
                    {
                      "text":
                          "Bạn là nhân viên tư vấn và trợ lý ảo thông minh của cửa hàng thời trang E-Fashion tại Việt Nam. "
                          "Hãy trả lời khách hàng một cách thân thiện, lịch sự, ngắn gọn (tối đa 2-3 câu) bằng tiếng Việt để tư vấn mua sắm, chọn size, phối đồ hoặc hỗ trợ đơn hàng. "
                          "Câu hỏi của khách hàng: '$userQuery'"
                    }
                  ]
                }
              ]
            },
            options: Options(
              headers: {'Content-Type': 'application/json'},
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

          if (response.statusCode == 200 &&
              response.data['candidates'] != null &&
              (response.data['candidates'] as List).isNotEmpty) {
            reply = response.data['candidates'][0]['content']['parts'][0]['text']
                .toString()
                .trim();
          }
        } catch (e) {
          debugPrint("Gemini API error: $e");
          reply = 'Dạ E-Fashion xin chào bạn! Đội ngũ chăm sóc khách hàng đã ghi nhận câu hỏi và sẽ hỗ trợ tư vấn chi tiết cho bạn ngay nhé!';
        }
      } else {
        reply = 'Dạ E-Fashion xin chào bạn! Bạn có thể cho shop biết thêm về yêu cầu chọn size hay mẫu sản phẩm bạn quan tâm nhé!';
      }

      if (reply.isEmpty) return;

      final botMessage = ChatMessage(
        message: reply,
        isMe: false,
        date: DateTime.now().toIso8601String(),
      );

      _messageReceived(receivedMessage: botMessage);
    });
  }

  void _messageReceived({required ChatMessage receivedMessage}) {
    emit(
      state.copyWith(chatMessages: [receivedMessage, ...state.chatMessages]),
    );
  }

  void _startChatStreamSubscription() {
    streamSubscription = _getChatStreamUseCase().listen((newMessage) {
      _messageReceived(receivedMessage: newMessage);
    });
  }

  @override
  Future<void> close() async {
    if (state.chatState == CubitState.success) {
      streamSubscription.cancel();
      await _closeSocketConnectionUseCase();
    }
    return super.close();
  }
}
