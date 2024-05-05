class AppStrings {
  const AppStrings._();

  static const String timeoutError =
      'Oops! The request took too long to process. Please check your internet connection and try again. If the issue persists, you can contact our support team for assistance.';

  static const String somethingWentWrong = 'Oops! Something went wrong. Please try again after some time.';

  static const String socketProblem = 'There has been a problem with your connectivity. Please check your internet connection and try again.';

  static const String noInternet = 'No internet connection. Please connect to the internet and try again.';
}

class AppPrompts {
  const AppPrompts._();

  static String titlePrompt(String title) => '''Input: $title
Output: Phrase of Potential business insights from the video title that can be written in an email

Instructions:
1. Analyze the provided YouTube video title to extract specific insights or themes relevant to your business.
2. Identify only one main subject matter or message conveyed by the title, including any keywords, phrases, or tone used.
3. Consider potential subtopics or areas of interest suggested by the title.
4. Craft a concise analysis aimed at generating interest or initiating conversation with the video owner as a potential client.
5. Keep the output within 3-4 words.
6. Do not include any special character.
7. Do not include the words 'Input' and 'Output' in your Output''';

  static String namePrompt(String name, String channel, String description) => '''
I want you to act as an Data extractor and extract name that I can address to in an email from the following details of a Youtube Channel. Decode the data and find the name of the Channel Owner if possible.

Input:
Username: $name
Channel Name: $channel
Description: """$description"""

Instruction:
Do not include anything other than the name in the output

Output:
If the user's name is identified: First name of the user
Else: "Team $channel"''';
}
