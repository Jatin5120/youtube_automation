class AppStrings {
  const AppStrings._();

  static const String timeoutError =
      'Oops! The request took too long to process. Please check your internet connection and try again. If the issue persists, you can contact our support team for assistance.';

  static const String somethingWentWrong = 'Oops! Something went wrong. Please check your internet connection and try again.';

  static const String noInternet = 'No internet connection. Please connect to the internet and try again.';
}

class AppPrompts {
  const AppPrompts._();

  static String titlePrompt(String title) => '''Input: $title
Output: Analysis of the video topic or theme

Instructions:
1. Analyze the provided YouTube video title and generate a concise analysis of its primary topic or theme.
2. The analysis should focus on identifying the main subject matter or message conveyed by the video title.
3. Consider the keywords, phrases, or tone used in the title to infer the content of the video.
4. The output should not exceed 5-7 words.

Example:
Input: "If You Don't Get LOTS of Comments on Your Videos, Watch This ASAP"
Output: "Getting comments"''';

  static String namePrompt(String name, String description) =>
      '''Analyze the following and identify the name of the user from his YouTube username and description
Input: 
  Username: $name
  Description: $description

Output: 
  if you found the name: Name of the user
  else: "Not found"

Example:
Input: 
  Name: "Another Homosapien"
  Description: "Another Homosapien: I am just another one. And that's my power.

Coming onto content, here's what I am focusing on currently:

1. Videos to help anyone who thinks they wanna have a career in the Computer Science(programming), Digital Marketing, and general human problems as Procrastination or making money while being a student by focusing on developing skills.

2. My learnings(Economy, Microbiome etc.)

3. My opinions(How to choose college, courses, girlfriend ;))

4. Whatever the heck I want!!"
Output: "Not found"

Input:
  Name: "Rian Doris"
  Description: "Rían Doris is the Co-Founder & CEO of Flow Research Collective, the world's leading peak performance research and training institute focused on decoding the neuroscience of flow states and helping leaders and their teams unlock flow states consistently. Clients include Accenture, Audi, Facebook, Bain & the US Airforce.

Along with being listed on Forbes 30 Under 30 Rian's thought leadership has been featured in Fast Company, PBS and Big Think and he hosts Flow Research Collective Radio, an iTunes top 10 science podcast.

Rían holds a degree in Philosophy, Politics & Economics (PPE) from Trinity College Dublin, an MSC in Neuroscience at King's College, London and an MBA. Rian is currently pursuing a PhD at the University of Birmingham.

Prior to co-founding Flow Research Collective with Steven Kotler, Rian worked with NYT Bestselling Author Keith Ferazzi, and 12X NYT Bestselling Author Dr. Dan Siegel, distinguished fellow of the American Psychiatric Association."
Output: "Rian Doris"

Do Not include the work "Outpu" in the output
''';
}
