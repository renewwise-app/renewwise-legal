/// Placeholder response from [RenewWiseAssistantService.answerQuestion].
class AssistantAnswer {
  const AssistantAnswer({
    required this.question,
    required this.answer,
    required this.source,
  });

  final String question;
  final String answer;
  final AssistantAnswerSource source;
}

enum AssistantAnswerSource {
  placeholder,
}
