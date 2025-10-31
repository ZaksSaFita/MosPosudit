class MessageSendRequestDto {
  final String content;

  MessageSendRequestDto({required this.content});

  Map<String, dynamic> toJson() => {
        'content': content,
      };
}

